import 'package:flutter/material.dart';

import '../client/event.dart';
import '../client/filter.dart';
import '../main.dart';
import '../util/later_function.dart';
import '../util/string_util.dart';

class SingleEventProvider extends ChangeNotifier with LaterFunction {
  Map<String, Event> _eventsMap = {};

  Map<String, String> _needUpdateIds = {};

  Map<String, String> _handingIds = {};

  List<Event> _penddingEvents = [];

  Event? getEvent(String id, {String? eventRelayAddr, bool queryData = true}) {
    var event = _eventsMap[id];
    if (event != null) {
      return event;
    }

    if (!queryData) {
      return null;
    }

    if (_needUpdateIds[id] == null) {
      eventRelayAddr ??= "";
      _needUpdateIds[id] = eventRelayAddr;
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

  void onEvent(Event event) {
    _penddingEvents.add(event);
    later(_laterCallback, null);
  }

  void _laterSearch() {
    if (_needUpdateIds.isNotEmpty) {
      List<String> tempIds = [..._needUpdateIds.keys];
      var filter = Filter(ids: tempIds);
      var subscriptId = StringUtil.rndNameStr(12);
      // print("query filter ${jsonEncode(filter.toJson())}");
      nostr!.query([filter.toJson()], onEvent, id: subscriptId, onComplete: () {
        // log("singleEventProvider onComplete $tempIds");
        for (var id in tempIds) {
          var eventRelayAddr = _handingIds.remove(id);
          if (StringUtil.isNotBlank(eventRelayAddr) && _eventsMap[id] == null) {
            // eventRelayAddr exist and event not found, send a single query again.
            print(
                "single event ${id} not found! begin to query again from ${eventRelayAddr}.");
            var filter = Filter(ids: tempIds);
            nostr!.query([filter.toJson()], onEvent,
                tempRelays: [eventRelayAddr!]);
          }
        }
      });

      for (var entry in _needUpdateIds.entries) {
        _handingIds[entry.key] = entry.value;
      }
      _needUpdateIds.clear();
    }
  }
}
