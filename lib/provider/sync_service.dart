import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nostr.dart';
import 'package:nostr_sdk/utils/later_function.dart';
import 'package:nostr_sdk/utils/string_util.dart';

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

  // add some concurrent control
  static const int MAX_CONCURRENT_QUERIES = 10; // max concurrent queries
  int _currentRunningQueries = 0; // current running queries
  final List<Function()> _pendingQueries = []; // pending queries queue

  // key - int
  static const String KEY_SYNC_INIT_TIME = "syncInitTime";

  // key - List<String>
  static const String KEY_SYNC_TASK = "syncTaskKey";

  // key - '{"pubkey": "[]"}'
  static const String KEY_USERS_SYNC_TASK = "usersSyncTaskKey";

  // max relay num for each person
  static const int MAX_PERSON_RELAY_NUM = 3;

  String _getItemKey(SyncTaskItem taskItem) {
    return "${taskItem.syncType}_${taskItem.value}";
  }

  void reload() {
    // sharedPreferences.remove(KEY_SYNC_INIT_TIME);
    // sharedPreferences.remove(KEY_SYNC_TASK);
    // sharedPreferences.remove(KEY_USERS_SYNC_TASK);

    initTime = sharedPreferences.getInt(KEY_SYNC_INIT_TIME);
    if (initTime == null) {
      initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000 -
          const Duration(days: 7).inSeconds;
      sharedPreferences.setInt(KEY_SYNC_INIT_TIME, initTime!);
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

  Future<void> startSyncTask({Nostr? targetNostr}) async {
    targetNostr ??= nostr;
    if (targetNostr == null) {
      return;
    }

    if (_subscriptionIds.isNotEmpty) {
      for (var entry in _subscriptionIds.entries) {
        var relayAddr = entry.key;
        var subscriptionId = entry.value;

        targetNostr.unsubscribe(subscriptionId);
      }
    }
    _subscriptionIds.clear();

    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    Set<String> myRelaysSet = {};
    var nostrNormalRelays = targetNostr.normalRelays();
    for (var relay in nostrNormalRelays) {
      if (relay.relayStatus.readAccess) {
        myRelaysSet.add(relay.url);
      }
    }
    List<String> myRelayList = myRelaysSet.toList();

    Map<String, SyncRelayTask> relayTaskMap = {};

    // find all pubkeys in syncTaskMap and load data from DB
    List<String> pubkeys = [];
    for (var taskItem in syncTaskMap.values) {
      if (taskItem.syncType == SyncTaskType.PUBKEY) {
        pubkeys.add(taskItem.value);
      }
    }
    await metadataProvider.loadFromDBsSync(pubkeys);

    // clear pending queries
    _pendingQueries.clear();
    _currentRunningQueries = 0;

    for (var taskItem in syncTaskMap.values) {
      print("taskItem $taskItem");
      List<String>? relayList;
      taskItem = taskItem.clone();

      // find current task's relays and splite tasks to relay tasks to subscript new events later
      if (taskItem.syncType == SyncTaskType.PUBKEY) {
        var pubkey = taskItem.value;
        var relayListMetadata = metadataProvider.getRelayListMetadata(pubkey);
        if (relayListMetadata != null) {
          relayList = relayListMetadata.writeAbleRelays;
          if (relayList.length > MAX_PERSON_RELAY_NUM) {
            relayList = relayList.sublist(0, MAX_PERSON_RELAY_NUM);
          }

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
      if (taskItem.endTime == null) {
        filter.since = initTime;
        taskItem.startTime = initTime;
      } else {
        filter.since = taskItem.endTime!;
      }
      // TODO the time between startTime and endTime maybe very long and the query may not be complete in a time.
      // we should split the query to multiple queries.

      var filterMap = filter.toJson();
      // relays had bean found and try to sync events
      if (taskItem.syncType == SyncTaskType.PUBKEY) {
        filterMap['authors'] = [taskItem.value];
      } else if (taskItem.syncType == SyncTaskType.HASH_TAG) {
        filterMap["#t"] = [taskItem.value];
      }

      // add query to queue
      _addQueryToQueue(targetNostr, filterMap, relayList, taskItem, now);
    }

    // begin execute pending queries
    _executePendingQueries();

    // begin to subscript the new event using relayTaskMap
    for (var relayTask in relayTaskMap.values) {
      if (relayTask.pubkeys.isNotEmpty || relayTask.hashTags.isNotEmpty) {
        var filter = Filter(kinds: EventKindType.SUPPORTED_EVENTS, since: now);
        if (relayTask.pubkeys.isNotEmpty) {
          filter.authors = relayTask.pubkeys.toList();
        }
        var filterMap = filter.toJson();
        if (relayTask.hashTags.isNotEmpty) {
          filterMap["#t"] = relayTask.hashTags.toList();
        }

        var subscriptionId = StringUtil.rndNameStr(12);
        _subscriptionIds[relayTask.relay] = subscriptionId;
        targetNostr.subscribe(
          [filterMap],
          (e) {},
          id: subscriptionId,
          targetRelays: [relayTask.relay],
        );
      }
    }
  }

  // subscriptionIds map, key is relay, value is subscriptionId
  Map<String, String> _subscriptionIds = {};

  void _addQueryToQueue(Nostr targetNostr, Map<String, dynamic> filterMap,
      List<String> relayList, SyncTaskItem taskItem, int endTime) {
    var complete = Completer<bool>();
    var eoseTime = 0;

    _pendingQueries.add(() {
      print("query, filterMap: $filterMap, relayList: $relayList");
      targetNostr.query(
        [filterMap],
        (e) {},
        targetRelays: relayList,
        onComplete: () {
          complete.complete(true);
        },
        onEOSE: (relayAddr) {
          eoseTime++;
        },
      );
    });

    complete.future.then((v) {
      print("query complete, filterMap: $filterMap, relayList: $relayList");
      // query complete!
      taskItem.endTime = endTime;
      syncTaskMap[_getItemKey(taskItem)] = taskItem;
      later(saveSyncInfo);

      // query complete, reduce current running count and execute next query
      _currentRunningQueries--;
      _executePendingQueries();
    }).timeout(const Duration(seconds: 120), onTimeout: () {
      print(
          "query timeout, filterMap: $filterMap, relayList: $relayList, eoseTime: $eoseTime");
      if (eoseTime > 1) {
        print("query timeout bug eoseTime > 1");
        taskItem.endTime = endTime;
        syncTaskMap[_getItemKey(taskItem)] = taskItem;
        later(saveSyncInfo);
      }

      _currentRunningQueries--;
      _executePendingQueries();
    });
  }

  void _executePendingQueries() {
    while (_currentRunningQueries < MAX_CONCURRENT_QUERIES &&
        _pendingQueries.isNotEmpty) {
      var query = _pendingQueries.removeAt(0);
      _currentRunningQueries++;
      query();
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
