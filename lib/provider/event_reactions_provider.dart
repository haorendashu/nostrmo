import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/data/event_reactions.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/lazy_function.dart';

class EventReactionsProvider extends ChangeNotifier with LazyFunction {
  int update_time = 1000 * 60 * 10;

  Map<String, EventReactions> _eventReactionsMap = {};

  EventReactionsProvider() {
    lazyTimeMS = 2000;
  }

  EventReactions? get(String id) {
    var er = _eventReactionsMap[id];
    if (er == null) {
      // plan to pull
      _penddingIds[id] = 1;
      lazy(lazyFunc, null);
      // set a empty er to avoid pull many times
      er = EventReactions(id);
      _eventReactionsMap[id] = er;
    } else {
      var now = DateTime.now();
      // check dataTime if need to update
      if (now.millisecondsSinceEpoch - er.dataTime.millisecondsSinceEpoch >
          update_time) {
        _penddingIds[id] = 1;
        lazy(lazyFunc, null);
      }
      // set the access time, remove cache base on this time.
      er.access(now);
    }
    return er;
  }

  void lazyFunc() {
    if (_penddingIds.isNotEmpty) {
      _doPull();
    }
    if (_penddingEvents.isNotEmpty) {
      _handleEvent();
    }
  }

  Map<String, int> _penddingIds = {};

  void _doPull() {
    // Map<String, int> idMap = {};
    // for (var id in _penddingIds) {
    //   idMap[id] = 1;
    // }
    // _penddingIds.clear();

    var filter = Filter(e: _penddingIds.keys.toList());
    _penddingIds.clear();
    nostr!.pool.query([filter.toJson()], onEvent);
  }

  void onEvent(Event event) {
    _penddingEvents.add(event);
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
}
