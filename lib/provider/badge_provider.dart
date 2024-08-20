import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip58/nip58.dart';
import 'package:nostr_sdk/nostr.dart';

import '../main.dart';

class BadgeProvider extends ChangeNotifier {
  Event? badgeEvent;

  void wear(String badgeId, String eventId, {String? relayAddr}) async {
    var result = await NIP58.ware(
      nostr!,
      badgeId,
      eventId,
      relayAddr: relayAddr,
      badgeEvent: badgeEvent,
    );
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

    var filter = Filter(authors: [pubkey], kinds: [EventKind.BADGE_ACCEPT]);
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
      var badgeIds = NIP58.parseProfileBadge(badgeEvent!);
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
}
