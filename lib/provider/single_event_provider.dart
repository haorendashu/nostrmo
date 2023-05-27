import 'dart:developer';

import 'package:flutter/material.dart';

import '../client/event.dart';
import '../client/event_kind.dart' as kind;
import '../client/filter.dart';
import '../main.dart';
import '../util/later_function.dart';
import '../util/string_util.dart';

class SingleEventProvider extends ChangeNotifier with LaterFunction {
  Map<String, Event> _eventsMap = {};

  List<String> _needUpdateIds = [];

  Map<String, int> _handingIds = {};

  List<Event> _penddingEvents = [];

  Event? getEvent(String id) {
    var event = _eventsMap[id];
    if (event != null) {
      return event;
    }

    if (!_needUpdateIds.contains(id) && _handingIds[id] == null) {
      _needUpdateIds.add(id);
    }
    later(_laterCallback, null);

    return null;
  }

  void _laterCallback() {
    if (_needUpdateIds.isNotEmpty) {
      _laterSearch();
    }

    if (_penddingEvents.isNotEmpty) {
      _handlePenddingEvents();
    }
  }

  void _handlePenddingEvents() {
    for (var event in _penddingEvents) {
      var oldEvent = _eventsMap[event.id];
      if (oldEvent != null) {
        if (event.sources.isNotEmpty &&
            !oldEvent.sources.contains(event.sources[0])) {
          oldEvent.sources.add(event.sources[0]);
        }
      } else {
        _eventsMap[event.id] = event;
      }

      _handingIds.remove(event.id);
    }
    _penddingEvents.clear;
    notifyListeners();
  }

  void _onEvent(Event event) {
    _penddingEvents.add(event);
    later(_laterCallback, null);
  }

  void _laterSearch() {
    if (_needUpdateIds.isEmpty) {
      return;
    }

    var filter = Filter(ids: _needUpdateIds);
    var subscriptId = StringUtil.rndNameStr(16);
    List<String> tempIds = [];
    tempIds.addAll(_needUpdateIds);
    nostr!.query([filter.toJson()], _onEvent, id: subscriptId, onComplete: () {
      // log("singleEventProvider onComplete $tempIds");
      for (var id in tempIds) {
        _handingIds.remove(id);
      }
    });

    for (var id in _needUpdateIds) {
      _handingIds[id] = 1;
    }
    _needUpdateIds.clear();
  }
}
