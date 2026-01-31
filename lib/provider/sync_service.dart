import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nostr.dart';
import 'package:nostr_sdk/relay/relay_status.dart';
import 'package:nostr_sdk/utils/later_function.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../consts/client_connected.dart';
import '../consts/event_kind_type.dart';
import '../consts/sync_task_type.dart';
import '../data/feed_data.dart';
import '../data/sync_task_item.dart';
import '../main.dart';
import '../util/relay_filter.dart';

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
  static const int MAX_CONCURRENT_QUERIES = 20; // max concurrent queries
  int _currentRunningQueries = 0; // current running queries
  final List<Function()> _pendingQueries = []; // pending queries queue

  // key - int
  static const String KEY_SYNC_INIT_TIME = "syncInitTime";

  // key - List<String>
  static const String KEY_SYNC_TASK = "syncTaskKey";

  // key - '{"pubkey": "[]"}'
  static const String KEY_USERS_SYNC_TASK = "usersSyncTaskKey";

  // max relay num for each person
  static const int MAX_PERSON_RELAY_NUM = 4;

  static int PULL_INTERVAL = const Duration(days: 7).inSeconds;

  List<Function()> _syncCompleteCallback = [];

  void dispose() {
    _syncCompleteCallback.clear();
    _subscriptionIds.clear();
    _pendingQueries.clear();
  }

  String _getItemKey(SyncTaskItem taskItem) {
    return "${taskItem.syncType}_${taskItem.value}";
  }

  void reload() {
    // sharedPreferences.remove(KEY_SYNC_INIT_TIME);
    // sharedPreferences.remove(KEY_SYNC_TASK);
    // sharedPreferences.remove(KEY_USERS_SYNC_TASK);

    initTime = sharedPreferences.getInt(KEY_SYNC_INIT_TIME);
    if (initTime == null) {
      initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000 - PULL_INTERVAL;
      sharedPreferences.setInt(KEY_SYNC_INIT_TIME, initTime!);
    }

    var date = DateTime.fromMillisecondsSinceEpoch(initTime! * 1000);
    log("initDate is ${date.toIso8601String()}");

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

  Future<void> updateFromFeedDataList(
      List<FeedData> feedDataList, String currentPubkey) async {
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

    syncTaskMap = newTotalTaskMap;
    if (needAddTaskList.isNotEmpty || needRemoveTaskKeyList.isNotEmpty) {
      saveSyncInfo();
      await loadMetadatas();

      genQueryTasksAndExecute(nostr!, initTime!,
          untilTime: DateTime.now().millisecondsSinceEpoch ~/ 1000);
    }
  }

  List<String> myRelayList = [];

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

    Set<String> myRelaysSet = {};
    var nostrNormalRelays = targetNostr.normalRelays();
    for (var relay in nostrNormalRelays) {
      if (relay.relayStatus.readAccess) {
        myRelaysSet.add(relay.url);
      }
    }
    myRelayList = myRelaysSet.toList();

    await loadMetadatas();

    _doSync(targetNostr);
  }

  Future<void> loadMetadatas() async {
    // find all pubkeys in syncTaskMap and load data from DB
    List<String> pubkeys = [];
    for (var taskItem in syncTaskMap.values) {
      if (taskItem.syncType == SyncTaskType.PUBKEY) {
        pubkeys.add(taskItem.value);
      }
    }
    if (pubkeys.isNotEmpty) {
      await metadataProvider.loadMetadatas(pubkeys);
    }
  }

  int _startSyncTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  Future<void> _doSync(Nostr targetNostr) async {
    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _startSyncTime = now;

    genQueryTasksAndExecute(targetNostr, initTime!, untilTime: now);
  }

  void genQueryTasksAndExecute(Nostr targetNostr, int sinceTime,
      {int? untilTime}) {
    try {
      // clear pending queries
      _pendingQueries.clear();
      _currentRunningQueries = 0;

      for (var taskItem in syncTaskMap.values) {
        taskItem.startTime ??= initTime;
        print("taskItem $taskItem");
        List<String>? relayList;
        taskItem = taskItem.clone();

        // find current task's relays and splite tasks to relay tasks to subscript new events later
        if (taskItem.syncType == SyncTaskType.PUBKEY) {
          var pubkey = taskItem.value;
          var relayListMetadata = metadataProvider.getRelayListMetadata(pubkey);
          if (relayListMetadata != null) {
            relayList = [
              ...(relayListMetadata.writeAbleRelays
                  .skipWhile((relay) => RelayFilter.match(relay)))
            ];
            if (relayList.length > MAX_PERSON_RELAY_NUM) {
              // shuffle the relays to avoid some relays always can't connected, just try other relays.
              relayList.shuffle();
              relayList = relayList.sublist(0, MAX_PERSON_RELAY_NUM);
            }
          }
        } else if (taskItem.syncType == SyncTaskType.HASH_TAG) {
          if (taskItem.relays != null && taskItem.relays!.isNotEmpty) {
            relayList = taskItem.relays!;
          } else {
            relayList = myRelayList;
          }
        }

        if (relayList == null || relayList.isEmpty) {
          continue;
        }

        // handle filter base params and time
        var filter = Filter(
          kinds: EventKindType.SUPPORTED_EVENTS,
        );

        var filterMap = filter.toJson();
        // relays had bean found and try to sync events
        if (taskItem.syncType == SyncTaskType.PUBKEY) {
          filterMap['authors'] = [taskItem.value];
        } else if (taskItem.syncType == SyncTaskType.HASH_TAG) {
          filterMap["#t"] = [taskItem.value];
        }

        if (taskItem.startTime != null && sinceTime < taskItem.startTime!) {
          // the task's startTime is later than the sinceTime, query event before taskItem's startTime
          filterMap["since"] = sinceTime;
          filterMap["until"] = taskItem.startTime!;

          // add query to queue
          _addQueryToQueue(targetNostr, filterMap, relayList, taskItem,
              startTime: sinceTime);
        }

        if (untilTime != null) {
          int? _since;
          if (taskItem.endTime == null) {
            // endTime is null, it never sync, the begin time is the task's startTime, usually it's the initTime
            _since = taskItem.startTime;
          } else {
            // endTime is not null, it had synced before, use the last endTime as this time's beginTime
            _since = taskItem.endTime!;
          }

          if (_since != null && _since < untilTime) {
            filterMap = Map.from(filterMap);
            filterMap["since"] = _since;
            filterMap["until"] = untilTime;

            // add query to queue
            _addQueryToQueue(targetNostr, filterMap, relayList, taskItem,
                endTime: untilTime);
          }
        }

        // TODO the time between startTime and endTime maybe very long and the query may not be complete in a time.
        // we should split the query to multiple queries.
      }

      // begin execute pending queries
      _executePendingQueries();
    } catch (e) {
      print("_doSync catch error $e");
    }
  }

  // subscriptionIds map, key is relay, value is subscriptionId
  Map<String, String> _subscriptionIds = {};

  void _addQueryToQueue(Nostr targetNostr, Map<String, dynamic> filterMap,
      List<String> relayList, SyncTaskItem taskItem,
      {int? startTime, int? endTime}) {
    _pendingQueries.add(() {
      var complete = Completer<bool>();
      var eoseTime = 0;

      int eventCount = 0;

      // print("query, filterMap: $filterMap, relayList: $relayList");
      targetNostr.query(
        [filterMap],
        (e) {
          eventCount++;
        },
        targetRelays: relayList,
        onComplete: () {
          if (!complete.isCompleted) {
            complete.complete(true);
          }
        },
        onEOSE: (relayAddr) {
          eoseTime++;
          if (eoseTime > 1 && !complete.isCompleted) {
            complete.complete(true);
          }
        },
      );

      complete.future.then((v) {
        print(
            "query complete, filterMap: $filterMap, relayList: $relayList, eventCount $eventCount");
        // query complete!
        _getTaskItemAndUpdateTime(taskItem,
            startTime: startTime, endTime: endTime);
      }).timeout(const Duration(seconds: 90), onTimeout: () {
        print(
            "query timeout, filterMap: $filterMap, relayList: $relayList, eoseTime: $eoseTime, eventCount $eventCount");
        if (eoseTime > 1) {
          print("query timeout but eoseTime > 1");
          _getTaskItemAndUpdateTime(taskItem,
              startTime: startTime, endTime: endTime);
        }

        // // it was timeout now, find if the relay is connect timeout
        // for (var relayAddr in relayList) {
        //   var relay = targetNostr.getRelay(relayAddr);
        //   if (relay != null) {
        //     if (relay.relayStatus.connected == ClientConneccted.UN_CONNECT ||
        //         relay.relayStatus.connected == ClientConneccted.CONNECTING &&
        //             relay.relayStatus.noteReceived == 0) {
        //       // relay find and relay not connected and relay never receive any event
        //       // TODO maybe we should filter these relays when we syncing next time.
        //     }
        //   }
        // }
      }).whenComplete(() {
        // query complete, reduce current running count and execute next query
        _currentRunningQueries--;
        _executePendingQueries();
      });
    });
  }

  void _getTaskItemAndUpdateTime(SyncTaskItem taskItem,
      {int? startTime, int? endTime}) {
    var key = _getItemKey(taskItem);
    var _taskItem = syncTaskMap[key];
    if (_taskItem != null) {
      if (startTime != null) {
        _taskItem.startTime = startTime;
        syncTaskMap[key] = _taskItem;
        later(saveSyncInfo);
      }
      if (endTime != null) {
        _taskItem.endTime = endTime;
        syncTaskMap[key] = _taskItem;
        later(saveSyncInfo);
      }
    }
  }

  Future<void> _executePendingQueries() async {
    while (_currentRunningQueries < MAX_CONCURRENT_QUERIES &&
        _pendingQueries.isNotEmpty) {
      var query = _pendingQueries.removeAt(0);
      _currentRunningQueries++;
      query();
    }

    if (_currentRunningQueries <= 0 && _pendingQueries.isEmpty) {
      log("all sync queries complete!");
      notifySyncComplete();

      var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // log("sync time: ${now - _startSyncTime}");
      if (now - _startSyncTime < 60) {
        await Future.delayed(const Duration(seconds: 60));
      }

      if (nostr != null && !nostr!.isClose()) {
        if (_currentRunningQueries <= 0 && _pendingQueries.isEmpty) {
          _currentRunningQueries = 0;
          // check again, avoid call doSync method again.
          _doSync(nostr!);
        }
      }
    }
  }

  void checkOrSyncOldData(int sinceTime) {
    if (initTime != null && sinceTime < initTime! + PULL_INTERVAL / 2) {
      initTime = initTime! - PULL_INTERVAL;
      sharedPreferences.setInt(KEY_SYNC_INIT_TIME, initTime!);

      genQueryTasksAndExecute(nostr!, initTime!);
    }
  }

  void addSyncCompleteCallback(Function() callback) {
    _syncCompleteCallback.add(callback);
  }

  void notifySyncComplete() {
    for (var callback in _syncCompleteCallback) {
      callback();
    }
  }

  void removeSyncCompleteCallback(Function() callback) {
    _syncCompleteCallback.remove(callback);
  }
}

class SyncRelayTask {
  String relay;

  Set<String> pubkeys;

  Set<String> hashTags;

  SyncRelayTask(this.relay, this.pubkeys, this.hashTags);
}
