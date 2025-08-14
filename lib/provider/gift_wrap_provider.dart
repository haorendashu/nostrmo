import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip59/gift_wrap_util.dart';
import 'package:nostr_sdk/nostr.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../data/event_db.dart';
import '../main.dart';

class GiftWrapProvider extends ChangeNotifier {
  static const GIFT_WRAP_INIT_TIME = 1672502400;

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

  int TIME_FLAG = 60 * 60 * 24 * 2;

  void query({Nostr? targetNostr, int? since, bool initQuery = false}) {
    targetNostr ??= nostr;
    if (since == null) {
      if (initQuery) {
        // haven't query before
        if (box.isEmpty()) {
          // since = 1672502400;
          since = null;
        } else {
          var oldestEvent = box.oldestEvent;
          since = oldestEvent!.createdAt - TIME_FLAG;
        }
      } else {
        // query news
        since = DateTime.now().millisecondsSinceEpoch ~/ 1000 - TIME_FLAG;
      }
    }

    var filter = Filter(
      kinds: [EventKind.GIFT_WRAP],
      since: since,
      p: [nostr!.publicKey],
    );
    var queryId = StringUtil.rndNameStr(10);

    // the targetNostr maybe haven't complete init, so with a same queryId, the last query will not works.
    if (initQuery) {
      targetNostr!.addInitQuery([filter.toJson()], onEvent, id: queryId);
    }
    targetNostr!.query([filter.toJson()], onEvent, id: queryId);
  }

  Future<void> onEvent(Event e) async {
    if (box.add(e)) {
      // This is an new event.
      // decode this event.
      try {
        var sourceEvent = await GiftWrapUtil.getRumorEvent(nostr!, e);

        // some event need some handle
        if (sourceEvent != null) {
          if (sourceEvent.kind == EventKind.PRIVATE_DIRECT_MESSAGE ||
              sourceEvent.kind == EventKind.PRIVATE_FILE_MESSAGE) {
            // private DM, handle by dmProvider
            dmProvider.onEvent(sourceEvent);
          }
        }

        var keyIndex = settingProvider.privateKeyIndex!;
        EventDB.insert(keyIndex, e);
      } catch (e) {
        print("giftwrap onEvent error $e");
      }
    }
  }
}
