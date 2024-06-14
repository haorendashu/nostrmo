import 'dart:developer';

import 'package:flutter/material.dart';

import '../client/event.dart';
import '../client/event_kind.dart';
import '../client/filter.dart';
import '../data/event_reactions.dart';
import '../main.dart';
import '../util/when_stop_function.dart';

class EventReactionsProvider extends ChangeNotifier with WhenStopFunction {
  int update_time = 1000 * 60 * 10;

  Map<String, EventReactions> _eventReactionsMap = {};

  EventReactionsProvider() {
    whenStopMS = 200;
  }

  List<EventReactions> allReactions() {
    return _eventReactionsMap.values.toList();
  }

  void addRepost(String id) {
    var er = _eventReactionsMap[id];
    if (er != null) {
      er = er.clone();
      er.repostNum++;
      _eventReactionsMap[id] = er;
      notifyListeners();
    }
  }

  void addLike(String id, Event likeEvent) {
    var er = _eventReactionsMap[id];
    if (er != null) {
      er = er.clone();
      er.onEvent(likeEvent);
      _eventReactionsMap[id] = er;
      notifyListeners();
    }
  }

  void deleteLike(String id) {
    var er = _eventReactionsMap[id];
    if (er != null) {
      er = er.clone();
      if (er.myLikeEvents != null) {
        var length = er.myLikeEvents!.length;
        er.likeNum -= length;

        for (var e in er.myLikeEvents!) {
          var likeText = EventReactions.getLikeText(e);
          var num = er.likeNumMap[likeText];
          if (num != null && num > 0) {
            num--;

            if (num > 0) {
              er.likeNumMap[likeText] = num;
            } else {
              er.likeNumMap.remove(likeText);
            }
          }
        }
      } else {
        er.likeNum--;
      }
      er.myLikeEvents = null;
      _eventReactionsMap[id] = er;
      notifyListeners();
    }
  }

  // void update(String id) {
  //   _penddingIds[id] = 1;
  //   whenStop(laterFunc);
  // }

  EventReactions? get(String id, {bool avoidPull = false}) {
    var er = _eventReactionsMap[id];
    if (er == null) {
      _localPenddingIds[id] = avoidPull;
      whenStop(laterFunc);

      // set a empty er to avoid pull many times
      er = EventReactions(id);
      _eventReactionsMap[id] = er;
    } else {
      var now = DateTime.now();
      // check dataTime if need to update
      if (now.millisecondsSinceEpoch - er.dataTime.millisecondsSinceEpoch >
          update_time) {
        _penddingIds[id] = 1;
        // later(laterFunc, null);
        whenStop(laterFunc);
      }
      // set the access time, remove cache base on this time.
      er.access(now);
    }
    return er;
  }

  Map<String, int> localQueringCache = {};

  _handleLocalPenddings() {
    var entries = _localPenddingIds.entries;
    for (var entry in entries) {
      var id = entry.key;
      var avoidPull = entry.value;

      _loadFromRelayLocal(id)
          .timeout(const Duration(seconds: 2))
          .onError((e, st) {
        return false;
      }).then((exist) {
        if (!exist && !avoidPull) {
          // not exist and not avoidPull, or timeout
          _penddingIds[id] = 1;
        }
      });
    }
    _localPenddingIds.clear();
  }

  List<int> SUPPORT_EVENT_KINDS = [
    EventKind.TEXT_NOTE,
    EventKind.REPOST,
    EventKind.GENERIC_REPOST,
    EventKind.REACTION,
    EventKind.ZAP
  ];

  Future<bool> _loadFromRelayLocal(String id) async {
    if (relayLocalDB != null && localQueringCache[id] == null) {
      try {
        // stop other quering
        localQueringCache[id] = 1;

        var filter = Filter(e: [id], kinds: SUPPORT_EVENT_KINDS);
        var eventMaps = await relayLocalDB!.doQueryEvent(filter.toJson());
        var events = relayLocalDB!.loadEventFromMaps(eventMaps);
        if (events.isNotEmpty) {
          // print("Event Reactions load from relayDB $id");
          onEvents(events);
          whenStop(laterFunc);

          return true;
        }
      } finally {
        localQueringCache.remove(id);
      }
    }

    return false;
  }

  void laterFunc() {
    log("laterFunc call!");
    if (_localPenddingIds.isNotEmpty) {
      _handleLocalPenddings();
    }
    if (_penddingIds.isNotEmpty) {
      _doPull();
    }
    if (_penddingEvents.isNotEmpty) {
      _handleEvent();
    }
  }

  Map<String, bool> _localPenddingIds = {};

  Map<String, int> _penddingIds = {};

  void _doPull() {
    if (_penddingIds.isEmpty) {
      return;
    }

    List<Map<String, dynamic>> filters = [];
    for (var id in _penddingIds.keys) {
      var filter = Filter(e: [id], kinds: SUPPORT_EVENT_KINDS);
      filters.add(filter.toJson());
    }
    _penddingIds.clear();
    nostr!.query(filters, onEvent);
  }

  void addEventAndHandle(Event event) {
    onEvent(event);
    laterFunc();
  }

  void onEvent(Event event) {
    _penddingEvents.add(event);
  }

  void onEvents(List<Event> events) {
    _penddingEvents.addAll(events);
  }

  List<Event> _penddingEvents = [];

  void _handleEvent() {
    bool updated = false;

    for (var event in _penddingEvents) {
      for (var tag in event.tags) {
        if (tag.length > 1) {
          var tagType = tag[0] as String;
          if (tagType == "e") {
            var id = tag[1] as String;
            var er = _eventReactionsMap[id];
            if (er == null) {
              er = EventReactions(id);
              _eventReactionsMap[id] = er;
            } else {
              er = er.clone();
              _eventReactionsMap[id] = er;
            }

            if (er.onEvent(event)) {
              updated = true;
            }
          }
        }
      }
    }
    _penddingEvents.clear();

    if (updated) {
      notifyListeners();
    }
  }

  void removePendding(String id) {
    _penddingIds.remove(id);
    _localPenddingIds.remove(id);
  }

  void clear() {
    _eventReactionsMap.clear();
  }
}
