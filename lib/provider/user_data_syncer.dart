import 'dart:async';

import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostrmo/main.dart';

class UserDataSyncer {
  static EventMemBox remoteEventMemBox = EventMemBox(sortAfterAdd: false);

  static EventMemBox localAndCacheEventMemBox =
      EventMemBox(sortAfterAdd: false);

  static Future<void> beginToSync() async {
    print("beginToSync data to remote");

    remoteEventMemBox.clear();
    localAndCacheEventMemBox.clear();
    var pubkey = nostr!.publicKey;

    var filter = Filter(authors: [pubkey], limit: 100);

    {
      var completer = Completer();
      nostr!.query(
        [filter.toJson()],
        onRemoteEvent,
        onComplete: () {
          completer.complete();
        },
        relayTypes: RelayType.ONLY_NORMAL,
      );
      await completer.future;
    }
    // remote data query complete

    {
      var completer = Completer();
      nostr!.query(
        [filter.toJson()],
        onLocalEvent,
        onComplete: () {
          completer.complete();
        },
        relayTypes: RelayType.CACHE_AND_LOCAL,
      );
      await completer.future;
    }

    var localEvents = localAndCacheEventMemBox.all();
    for (var e in localEvents) {
      var remoteEvent = remoteEventMemBox.getById(e.id);
      if (remoteEvent == null) {
        // This event not exit at remote, sync it to remote
        print("syncer send event to remote!");
        nostr!.sendEvent(e);
      } else {
        // This event exist at remote
        // Due to read relays can not the same with write relays, so it can't sync between remote relays.
      }
    }

    remoteEventMemBox.clear();
    localAndCacheEventMemBox.clear();
  }

  static void onRemoteEvent(Event e) {
    remoteEventMemBox.add(e);
  }

  static void onLocalEvent(Event e) {
    localAndCacheEventMemBox.add(e);
  }
}
