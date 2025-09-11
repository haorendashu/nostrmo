import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/utils/later_function.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../main.dart';

class ReplaceableEventProvider extends ChangeNotifier with LaterFunction {
  Map<String, Event> _eventsMap = {};

  Map<String, AId> _needUpdateIds = {};

  Map<String, AId> _handingIds = {};

  Map<String, List<String>> _aidRelays = {};

  Event? getEvent(AId aId, {List<String>? relays}) {
    var aIdStr = aId.toAString();
    var event = _eventsMap[aIdStr];
    if (event != null) {
      return event;
    }

    if (_needUpdateIds[aIdStr] == null && _handingIds[aIdStr] == null) {
      _needUpdateIds[aIdStr] = aId;
      if (relays != null) {
        _aidRelays[aIdStr] = relays;
      }
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

    // 1. try to find the event from current relays.
    List<AId> tempIds = [];
    List<Map<String, dynamic>> filters = [];
    for (var entry in _needUpdateIds.entries) {
      var aid = entry.value;

      var filter = Filter(authors: [aid.pubkey], kinds: [aid.kind]);
      var filterMap = filter.toJson();
      filterMap["#d"] = [aid.title];

      filters.add(filterMap);
      tempIds.add(aid);
    }
    nostr!.query(filters, _onEvent, onComplete: () {
      // 2. If the event is not found, try to find it from target relays.
      // log("singleEventProvider onComplete $tempIds");
      Map<AId, List<String>> needTryIds = {};
      for (var id in tempIds) {
        var aidStr = id.toAString();
        _handingIds.remove(aidStr);

        var event = _eventsMap[aidStr];
        if (event == null) {
          // event not found! try to find it from target relays.
          var relays = _aidRelays[aidStr];
          if (relays != null) {
            needTryIds[id] = relays;
          }
        }

        _aidRelays.remove(aidStr);
      }

      for (var entry in needTryIds.entries) {
        var aid = entry.key;
        var relays = entry.value;

        print(
            "try to find event from target relays ${aid.toAString()} $relays");
        var filter = Filter(authors: [aid.pubkey], kinds: [aid.kind]);
        var filterMap = filter.toJson();
        filterMap["#d"] = [aid.title];

        nostr!.query([filterMap], _onEvent,
            targetRelays: relays, relayTypes: RelayType.ONLY_TEMP);
      }
    });

    _handingIds.addAll(_needUpdateIds);
    _needUpdateIds.clear();
  }
}
