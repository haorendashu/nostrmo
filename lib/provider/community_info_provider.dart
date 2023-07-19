import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip172/community_id.dart';
import '../client/event.dart';
import '../client/event_kind.dart' as kind;
import 'package:nostrmo/client/nip172/community_info.dart';

import '../client/filter.dart';
import '../main.dart';
import '../util/later_function.dart';
import '../util/string_util.dart';

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
    later(_laterCallback, null);

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
      var communityId = CommunityId.fromString(idStr);
      if (communityId == null) {
        continue;
      }

      var filter = Filter(
          kinds: [kind.EventKind.COMMUNITY_DEFINITION],
          authors: [communityId.pubkey]);
      var queryArg = filter.toJson();
      queryArg["#d"] = [communityId.title];
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
    later(_laterCallback, null);
  }

  void _handlePenddingEvents() {
    bool updated = false;

    for (var event in _penddingEvents) {
      var communityInfo = CommunityInfo.fromEvent(event);
      if (communityInfo != null) {
        var aid = communityInfo.communityId.toAString();
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
