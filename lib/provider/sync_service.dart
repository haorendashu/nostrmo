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

///
/// SyncService to handle sync task.
/// The sync tasks are gen from feed data.
/// These sync tasks are for all users and each user's sync task info also should be saved.
/// Everytime after user's feed data is updated, his's sync task info also should be updated.
/// And then the total sync tasks info also should be updated aggregating all user's sync task info.
///
/// [SyncTaskItem] is the sync task item.
/// [initTime] is the init time of sync service, this value will gen when this service is first init.
class SyncService with LaterFunction, ChangeNotifier {
  Map<String, SyncTaskItem> syncTaskMap = {};

  int? initTime;

  // key - int
  static const String KEY_SYNC_INIT_TIME = "syncInitTime";

  // key - List<String>
  static const String KEY_SYNC_TASK = "syncTaskKey";

  // key - '{"pubkey": "[]"}'
  static const String KEY_USERS_SYNC_TASK = "usersSyncTaskKey";

  String _getItemKey(SyncTaskItem taskItem) {
    return "${taskItem.syncType}_${taskItem.value}";
  }

  void reload() {
    var initTime = sharedPreferences.getInt(KEY_SYNC_INIT_TIME);
    if (initTime == null) {
      initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      sharedPreferences.setInt(KEY_SYNC_INIT_TIME, initTime);
    }

    syncTaskMap.clear();
    var taskItemTextList = sharedPreferences.getStringList(KEY_SYNC_TASK) ?? [];
    for (var taskItemText in taskItemTextList) {
      var taskItem = SyncTaskItem.fromJson(jsonDecode(taskItemText));
      syncTaskMap[_getItemKey(taskItem)] = taskItem;
    }
  }

  void saveSyncInfo() {
    var taskItemTextList =
        syncTaskMap.values.map((e) => jsonEncode(e.toJson())).toList();
    sharedPreferences.setStringList(KEY_SYNC_TASK, taskItemTextList);
  }

  /// Get the users sync task map.
  /// The map key is the user's pubkey.
  /// The map value is the user's sync task list.
  Map<String, List<SyncTaskItem>> getUsersSyncTaskMap() {
    var usersSyncTaskText =
        sharedPreferences.getString(KEY_USERS_SYNC_TASK) ?? "{}";
    var usersSyncTaskMapItf =
        jsonDecode(usersSyncTaskText) as Map<String, dynamic>;
    Map<String, List<SyncTaskItem>> usersSyncTaskMap = {};
    for (var entry in usersSyncTaskMapItf.entries) {
      List<SyncTaskItem> list = [];
      var pubkey = entry.key;
      var taskTextList = entry.value;
      if (taskTextList is List) {
        for (var taskItemText in taskTextList) {
          var taskItem = SyncTaskItem.fromJson(jsonDecode(taskItemText));
          list.add(taskItem);
        }
      }

      usersSyncTaskMap[pubkey] = list;
    }

    return usersSyncTaskMap;
  }

  void saveUsersSyncTaskMap(Map<String, List<SyncTaskItem>> usersSyncTaskMap) {
    var usersSyncTaskMapItf = <String, dynamic>{};
    for (var entry in usersSyncTaskMap.entries) {
      var pubkey = entry.key;
      var taskList = entry.value;
      var taskTextList =
          taskList.map((e) => jsonEncode(e.toSimpleJson())).toList();
      usersSyncTaskMapItf[pubkey] = taskTextList;
    }

    var usersSyncTaskText = jsonEncode(usersSyncTaskMapItf);
    sharedPreferences.setString(KEY_USERS_SYNC_TASK, usersSyncTaskText);
  }

  void updateFromFeedDataList(
      List<FeedData> feedDataList, String currentPubkey) {
    // update current's syncTaskList to usersSyncTaskMap
    var usersSyncTaskMap = getUsersSyncTaskMap();
    List<SyncTaskItem> currentTaskItems = [];
    for (var feedData in feedDataList) {
      for (var data in feedData.datas) {
        if (data.length > 1) {
          var syncType = data[0] as int;
          var value = data[1] as String;
          var taskItem = SyncTaskItem(syncType, value);
          currentTaskItems.add(taskItem);
        }
      }
    }
    usersSyncTaskMap[currentPubkey] = currentTaskItems;
    saveUsersSyncTaskMap(usersSyncTaskMap);

    List<SyncTaskItem> needAddTaskList = [];
    Map<String, SyncTaskItem> newTotalTaskMap = {};
    for (var taskList in usersSyncTaskMap.values) {
      for (var taskItem in taskList) {
        var key = _getItemKey(taskItem);
        newTotalTaskMap[key] = taskItem;

        var oldTask = syncTaskMap[key];
        if (oldTask == null) {
          // oldTask is null, need add
          syncTaskMap[key] = taskItem;
          needAddTaskList.add(taskItem);
        }
      }
    }
    List<String> needRemoveTaskKeyList = [];
    for (var taskItem in syncTaskMap.values) {
      var key = _getItemKey(taskItem);
      var newTaskItem = newTotalTaskMap[key];
      if (newTaskItem == null) {
        needRemoveTaskKeyList.add(key);
      }
    }
    for (var needRemoveTaskKey in needRemoveTaskKeyList) {
      syncTaskMap.remove(needRemoveTaskKey);
    }

    if (needAddTaskList.isNotEmpty || needRemoveTaskKeyList.isNotEmpty) {
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
