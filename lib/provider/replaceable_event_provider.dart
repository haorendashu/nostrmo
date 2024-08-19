import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../main.dart';
import '../util/later_function.dart';

class ReplaceableEventProvider extends ChangeNotifier with LaterFunction {
  Map<String, Event> _eventsMap = {};

  Map<String, AId> _needUpdateIds = {};

  Map<String, AId> _handingIds = {};

  Event? getEvent(AId aId) {
    var aIdStr = aId.toAString();
    var event = _eventsMap[aIdStr];
    if (event != null) {
      return event;
    }

    if (_needUpdateIds[aIdStr] == null && _handingIds[aIdStr] == null) {
      _needUpdateIds[aIdStr] = aId;
    }
    later(_laterCallback);

    return null;
  }

  void _laterCallback() {
    if (_needUpdateIds.isNotEmpty) {
      _laterSearch();
    }
  }

  void _onEvent(Event event) {
    String? aIdString;

    // find the aid
    var length = event.tags.length;
    for (var i = 0; i < length; i++) {
      var tag = event.tags[i];

      var tagLength = tag.length;
      if (tagLength > 1 && tag[1] is String) {
        var tagKey = tag[0];
        var value = tag[1] as String;
        if (tagKey == "d") {
          aIdString = "${event.kind}:${event.pubkey}:$value";
          break;
        }
      }
    }

    if (StringUtil.isBlank(aIdString)) {
      return;
    }

    var oldEvent = _eventsMap[aIdString];
    if (oldEvent == null) {
      // update null
      _eventsMap[aIdString!] = event;
    } else {
      if (event.createdAt > oldEvent.createdAt) {
        // update new
        _eventsMap[aIdString!] = event;
      }
    }

    notifyListeners();
  }

  void _laterSearch() {
    if (_needUpdateIds.isEmpty) {
      return;
    }

    List<String> tempIds = [];
    List<Map<String, dynamic>> filters = [];
    for (var entry in _needUpdateIds.entries) {
      var aid = entry.value;

      var filter = Filter(authors: [aid.pubkey], kinds: [aid.kind]);
      var filterMap = filter.toJson();
      filterMap["#d"] = [aid.title];

      filters.add(filterMap);
    }
    var subscriptId = StringUtil.rndNameStr(16);
    nostr!.query(filters, _onEvent, id: subscriptId, onComplete: () {
      // log("singleEventProvider onComplete $tempIds");
      for (var id in tempIds) {
        _handingIds.remove(id);
      }
    });

    _handingIds.addAll(_needUpdateIds);
    _needUpdateIds.clear();
  }
}
