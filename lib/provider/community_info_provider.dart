import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip172/community_info.dart';
import 'package:nostr_sdk/utils/later_function.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../main.dart';

class CommunityInfoProvider extends ChangeNotifier with LaterFunction {
  Map<String, CommunityInfo> _cache = {};

  Map<String, int> _handingIds = {};

  List<String> _needPullIds = [];

  List<Event> _penddingEvents = [];

  CommunityInfo? getCommunity(String aid) {
    var ci = _cache[aid];
    if (ci != null) {
      return ci;
    }

    // add to query
    if (!_handingIds.containsKey(aid) && !_needPullIds.contains(aid)) {
      _needPullIds.add(aid);
    }
    later(_laterCallback);

    return null;
  }

  void _laterCallback() {
    if (_needPullIds.isNotEmpty) {
      _laterSearch();
    }

    if (_penddingEvents.isNotEmpty) {
      _handlePenddingEvents();
    }
  }

  void _laterSearch() {
    List<Map<String, dynamic>> filters = [];
    for (var idStr in _needPullIds) {
      var aId = AId.fromString(idStr);
      if (aId == null) {
        continue;
      }

      var filter = Filter(
          kinds: [EventKind.COMMUNITY_DEFINITION], authors: [aId.pubkey]);
      var queryArg = filter.toJson();
      queryArg["#d"] = [aId.title];
      filters.add(queryArg);
    }
    var subscriptId = StringUtil.rndNameStr(16);
    nostr!.query(filters, _onEvent, id: subscriptId);

    for (var pubkey in _needPullIds) {
      _handingIds[pubkey] = 1;
    }
    _needPullIds.clear();
  }

  void _onEvent(Event event) {
    _penddingEvents.add(event);
    later(_laterCallback);
  }

  void _handlePenddingEvents() {
    bool updated = false;

    for (var event in _penddingEvents) {
      var communityInfo = CommunityInfo.fromEvent(event);
      if (communityInfo != null) {
        var aid = communityInfo.aId.toAString();
        var oldInfo = _cache[aid];
        if (oldInfo == null || oldInfo.createdAt < communityInfo.createdAt) {
          _cache[aid] = communityInfo;
          updated = true;
        }
      }
    }
    _penddingEvents.clear;

    if (updated) {
      notifyListeners();
    }
  }
}
