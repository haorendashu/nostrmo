import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostrmo/client/event.dart';

import '../../client/event_kind.dart' as kind;
import '../client/filter.dart';
import '../client/nostr.dart';
import '../main.dart';

class BadgeProvider extends ChangeNotifier {
  Event? badgeEvent;

  void wear(String badgeId, String eventId, {String? relayAddr}) async {
    String content = "";
    List<dynamic> tags = [];

    if (badgeEvent != null) {
      content = badgeEvent!.content;
      tags = badgeEvent!.tags;
    } else {
      tags = [
        ["d", "profile_badges"]
      ];
    }

    tags.add(["a", badgeId]);
    var eList = ["e", eventId];
    if (relayAddr != null) {
      eList.add(relayAddr);
    }
    tags.add(eList);

    var newEvent =
        Event(nostr!.publicKey, kind.EventKind.BADGE_ACCEPT, tags, content);

    var result = await nostr!.sendEvent(newEvent);
    if (result != null) {
      badgeEvent = result;
      _parseProfileBadge();
      notifyListeners();
    }
  }

  void reload({bool initQuery = false, Nostr? targetNostr}) {
    targetNostr ??= nostr;

    String? pubkey;
    if (targetNostr != null) {
      pubkey = targetNostr.publicKey;
    }

    if (pubkey == null) {
      return;
    }

    var filter =
        Filter(authors: [pubkey], kinds: [kind.EventKind.BADGE_ACCEPT]);
    if (initQuery) {
      targetNostr!.addInitQuery([filter.toJson()], onEvent);
    } else {
      targetNostr!.query([filter.toJson()], onEvent);
    }
  }

  void onEvent(Event event) {
    if (badgeEvent == null || event.createdAt > badgeEvent!.createdAt) {
      badgeEvent = event;
      _parseProfileBadge();
      notifyListeners();
    }
  }

  Map<String, int> _badgeIdsMap = {};

  void _parseProfileBadge() {
    if (badgeEvent != null) {
      var badgeIds = parseProfileBadge(badgeEvent!);
      _badgeIdsMap = {};
      for (var badgeId in badgeIds) {
        _badgeIdsMap[badgeId] = 1;
      }
    }
  }

  bool containBadge(String badgeId) {
    if (_badgeIdsMap[badgeId] != null) {
      return true;
    }

    return false;
  }

  static List<String> parseProfileBadge(Event event) {
    List<String> badgeIds = [];

    for (var tag in event.tags) {
      if (tag[0] == "a") {
        var badgeId = tag[1];

        badgeIds.add(badgeId);
      }
    }

    return badgeIds;
  }
}
