import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';

import '../client/event_kind.dart' as kind;
import '../client/filter.dart';
import '../main.dart';
import '../util/later_function.dart';
import '../util/string_util.dart';

class SingleEventProvider extends ChangeNotifier with LaterFunction {
  Map<String, Event> _eventsMap = {};

  List<String> _needUpdateIds = [];

  List<Event> _penddingEvents = [];

  Event? getEvent(String id) {
    var event = _eventsMap[id];
    if (event != null) {
      return event;
    }

    if (!_needUpdateIds.contains(id)) {
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
      _eventsMap[event.id] = event;
    }
    _penddingEvents.clear;
    notifyListeners();
  }

  void _onEvent(Event event) {
    _penddingEvents.add(event);
    later(_laterCallback, null);
  }

  void _laterSearch() {
    var filter = Filter(
        kinds: [kind.EventKind.TEXT_NOTE], ids: _needUpdateIds, limit: 1);
    var subscriptId = StringUtil.rndNameStr(16);
    // use query and close after EOSE
    nostr!.pool.query([filter.toJson()], _onEvent, subscriptId);
    _needUpdateIds.clear();
  }
}
