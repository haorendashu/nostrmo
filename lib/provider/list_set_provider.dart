import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/utils/later_function.dart';
import 'package:nostrmo/main.dart';

class ListSetProvider extends ChangeNotifier with LaterFunction {
  // holder, hold the events.
  // key - “kind:pubkey:dTag”, value - event
  final Map<String, Event> _holder = {};

  List<String> _penddingAIdStrs = [];

  Map<String, int> _handingAIds = {};

  Event? getByAId(String aIdStr) {
    var event = _holder[aIdStr];
    if (event != null) {
      return event;
    }

    if (!_penddingAIdStrs.contains(aIdStr) && _handingAIds[aIdStr] == null) {
      _penddingAIdStrs.add(aIdStr);
    }

    later(_laterCallback);
    return null;
  }

  void _laterCallback() {
    if (_penddingAIdStrs.isNotEmpty) {
      List<Map<String, dynamic>> filters = [];
      for (var aIdStr in _penddingAIdStrs) {
        var aId = AId.fromString(aIdStr);
        if (aId != null) {
          var filter = Filter();
          filter.kinds = [aId.kind];
          filter.authors = [aId.pubkey];
          var filterMap = filter.toJson();
          filterMap["#d"] = [aId.title];
          filters.add(filterMap);

          _handingAIds[aIdStr] = 1;
        }
      }

      _penddingAIdStrs.clear();

      if (filters.isNotEmpty) {
        nostr!.query(filters, onEvent, onComplete: () {
          _handingAIds.clear();
        });
      }
    }
  }

  String getEventKey(Event event) {
    String dTag = "";
    for (var tag in event.tags) {
      if (tag is List && tag.length > 1) {
        var k = tag[0];
        var v = tag[1];
        if (k == "d") {
          dTag = v;
        }
      }
    }

    return "${event.kind}:${event.pubkey}:$dTag";
  }

  void onEvent(Event event) {
    var key = getEventKey(event);

    var oldEvent = _holder[key];
    if (oldEvent == null) {
      _holder[key] = event;
      _handingAIds.remove(key);
      notifyListeners();
    } else {
      if (event.createdAt > oldEvent.createdAt) {
        _holder[key] = event;
        _handingAIds.remove(key);
        notifyListeners();
      }
    }
  }
}
