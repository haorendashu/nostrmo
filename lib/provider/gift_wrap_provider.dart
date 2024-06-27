import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip59/gift_wrap_util.dart';

import '../client/event.dart';
import '../client/event_kind.dart';
import '../client/filter.dart';
import '../client/nip44/nip44_v2.dart';
import '../client/nostr.dart';
import '../client/signer/local_nostr_signer.dart';
import '../data/event_db.dart';
import '../data/event_mem_box.dart';
import '../main.dart';

class GiftWrapProvider extends ChangeNotifier {
  // The box to contains events.
  // Maybe it should only hold all eventIds.
  EventMemBox box = EventMemBox(sortAfterAdd: false);

  Future<void> init() async {
    var keyIndex = settingProvider.privateKeyIndex!;
    var events =
        await EventDB.list(keyIndex, [EventKind.GIFT_WRAP], 0, 10000000);

    for (var event in events) {
      box.add(event);
    }
    box.sort();
  }

  void query({Nostr? targetNostr, int? since}) {
    targetNostr ??= nostr;
    if (since == null && !box.isEmpty()) {
      var oldestEvent = box.oldestEvent;
      since = oldestEvent!.createdAt - 60 * 60 * 24 * 7;
    }

    var filter = Filter(
      kinds: [EventKind.GIFT_WRAP],
      since: since,
      p: [nostr!.publicKey],
    );

    // log("query!");
    targetNostr!.query([filter.toJson()], onEvent);
  }

  Future<void> onEvent(Event e) async {
    if (box.add(e)) {
      // This is an new event.
      // decode this event.
      var sourceEvent = await GiftWrapUtil.getRumorEvent(e);

      // some event need some handle
      if (sourceEvent != null) {
        if (sourceEvent.kind == EventKind.PRIVATE_DIRECT_MESSAGE) {
          // private DM, handle by dmProvider
          dmProvider.onEvent(sourceEvent);
        }
      }

      var keyIndex = settingProvider.privateKeyIndex!;
      EventDB.insert(keyIndex, e);
    }
  }
}
