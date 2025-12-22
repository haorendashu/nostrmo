import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nostr.dart';
import 'package:nostr_sdk/utils/later_function.dart';

import '../consts/event_kind_type.dart';
import '../consts/sync_task_type.dart';
import '../data/feed_data.dart';
import '../data/sync_task_item.dart';
import '../main.dart';

class SyncService with LaterFunction, ChangeNotifier {
  Map<String, SyncTaskItem> syncTaskMap = {};

  int? initTime;

  static const String initTimeKey = "syncInitTime";

  static const String syncTaskKey = "syncTaskKey";
  String _getItemKey(SyncTaskItem taskItem) {
    return "${taskItem.syncType}_${taskItem.value}";
  }

  void reload() {
    var initTime = sharedPreferences.getInt(initTimeKey);
    if (initTime == null) {
      initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      sharedPreferences.setInt(initTimeKey, initTime);
    }

    syncTaskMap.clear();
    var taskItemTextList = sharedPreferences.getStringList(syncTaskKey) ?? [];
    for (var taskItemText in taskItemTextList) {
      var taskItem = SyncTaskItem.fromJson(jsonDecode(taskItemText));
      syncTaskMap[_getItemKey(taskItem)] = taskItem;
    }
  }

  void saveSyncInfo() {
    var taskItemTextList =
        syncTaskMap.values.map((e) => jsonEncode(e.toJson())).toList();
    sharedPreferences.setStringList(syncTaskKey, taskItemTextList);
  }

  void updateFromFeedDataList(List<FeedData> feedDataList) {
    bool addedNew = false;

    for (var feedData in feedDataList) {
      for (var data in feedData.datas) {
        if (data.length > 1) {
          var syncType = data[0] as int;
          var value = data[1] as String;
          var taskItem = SyncTaskItem(syncType, value);
          var key = _getItemKey(taskItem);

          var oldTask = syncTaskMap[key];
          if (oldTask == null) {
            syncTaskMap[key] = taskItem;

            addedNew = true;
          }
        }
      }
    }

    if (addedNew) {
      saveSyncInfo();
    }
  }

  void startSyncTask({Nostr? targetNostr}) {
    targetNostr ??= nostr;
    if (targetNostr == null) {
      return;
    }

    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    Set<String> myRelaysSet = {};
    var nostrNormalRelays = nostr!.normalRelays();
    for (var relay in nostrNormalRelays) {
      if (relay.relayStatus.readAccess) {
        myRelaysSet.add(relay.url);
      }
    }
    List<String> myRelayList = myRelaysSet.toList();

    Map<String, SyncRelayTask> relayTaskMap = {};
    for (var taskItem in syncTaskMap.values) {
      List<String>? relayList;
      taskItem = taskItem.clone();

      // find current task's relays and splite tasks to relay tasks to subscript new events later
      if (taskItem.syncType == SyncTaskType.PUBKEY) {
        var pubkey = taskItem.value;
        var relayListMetadata = metadataProvider.getRelayListMetadata(pubkey);
        if (relayListMetadata != null) {
          relayList = relayListMetadata.writeAbleRelays;

          for (var relay in relayList) {
            var relayTask = _getOrGenRelayTask(relay, relayTaskMap);
            relayTask.pubkeys.add(pubkey);
          }
        }
      } else if (taskItem.syncType == SyncTaskType.HASH_TAG) {
        if (taskItem.relays != null && taskItem.relays!.isNotEmpty) {
          relayList = taskItem.relays!;
        } else {
          relayList = myRelayList;
        }

        for (var relay in relayList) {
          var relayTask = _getOrGenRelayTask(relay, relayTaskMap);
          relayTask.hashTags.add(taskItem.value);
        }
      }

      if (relayList == null || relayList.isEmpty) {
        continue;
      }

      // handle filter base params and time
      var filter = Filter(kinds: EventKindType.SUPPORTED_EVENTS, until: now);
      if (taskItem.startTime == null) {
        // taskItem's startTime is null, it means it is a new task, we should sync from initTime
        filter.since = initTime;
        taskItem.startTime = initTime;
      }
      taskItem.endTime = now;
      var filterMap = filter.toJson();

      // relays had bean found and try to sync events
      if (taskItem.syncType == SyncTaskType.PUBKEY) {
        filterMap['authors'] = [taskItem.value];
      } else if (taskItem.syncType == SyncTaskType.HASH_TAG) {
        filterMap["#t"] = [taskItem.value];
      }

      targetNostr.query(
        [filterMap],
        (e) {},
        targetRelays: relayList,
        onComplete: () {
          // query complete!
          syncTaskMap[_getItemKey(taskItem)] = taskItem;

          later(saveSyncInfo);
        },
      );
    }
  }

  SyncRelayTask _getOrGenRelayTask(
      String relay, Map<String, SyncRelayTask> relayTaskMap) {
    var relayTask = relayTaskMap[relay];
    if (relayTask == null) {
      relayTask = SyncRelayTask(relay, {}, {});
      relayTaskMap[relay] = relayTask;
    }

    return relayTask;
  }
}

class SyncRelayTask {
  String relay;

  Set<String> pubkeys;

  Set<String> hashTags;

  SyncRelayTask(this.relay, this.pubkeys, this.hashTags);
}
