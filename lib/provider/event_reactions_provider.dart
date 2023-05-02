import 'package:flutter/material.dart';

import '../client/event.dart';
import '../client/filter.dart';
import '../data/event_reactions.dart';
import '../main.dart';
import '../util/later_function.dart';
import '../util/when_stop_function.dart';

class EventReactionsProvider extends ChangeNotifier
    with LaterFunction, WhenStopFunction {
  int update_time = 1000 * 60 * 10;

  Map<String, EventReactions> _eventReactionsMap = {};

  EventReactionsProvider() {
    laterTimeMS = 2000;
    whenStopMS = 500;
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

  EventReactions? get(String id) {
    var er = _eventReactionsMap[id];
    if (er == null) {
      // plan to pull
      _penddingIds[id] = 1;
      // later(laterFunc, null);
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

  void laterFunc() {
    if (_penddingIds.isNotEmpty) {
      _doPull();
    }
    if (_penddingEvents.isNotEmpty) {
      _handleEvent();
    }
  }

  Map<String, int> _penddingIds = {};

  void _doPull() {
    if (_penddingIds.isEmpty) {
      return;
    }

    var filter = Filter(e: _penddingIds.keys.toList());
    _penddingIds.clear();
    nostr!.query([filter.toJson()], onEvent);
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
  }

  void clear() {
    _eventReactionsMap.clear();
  }
}
