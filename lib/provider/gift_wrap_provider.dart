import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip59/gift_wrap_util.dart';
import 'package:nostr_sdk/nostr.dart';

import '../data/event_db.dart';
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

  bool initQuery = true;

  int TIME_FLAG = 60 * 60 * 24 * 2;

  void query({Nostr? targetNostr, int? since}) {
    targetNostr ??= nostr;
    if (since == null && !box.isEmpty()) {
      if (initQuery) {
        // haven't query before
        var oldestEvent = box.oldestEvent;
        since = oldestEvent!.createdAt - TIME_FLAG;
      } else {
        // queried before, since change to two days before now avoid query too much event
        since = DateTime.now().millisecondsSinceEpoch ~/ 1000 - TIME_FLAG;
      }
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
      var sourceEvent = await GiftWrapUtil.getRumorEvent(nostr!, e);

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
