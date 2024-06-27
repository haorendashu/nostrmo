import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:nostrmo/client/client_utils/keys.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/client/nostr.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_util.dart';

import '../nip44/nip44_v2.dart';

class GiftWrapUtil {
  static Future<Event?> getRumorEvent(Event e) async {
    var rumorText = await nostr!.nostrSigner.nip44Decrypt(e.pubkey, e.content);
    if (rumorText == null) {
      return null;
    }

    var rumorJson = jsonDecode(rumorText);
    var rumorEvent = Event.fromJson(rumorJson);

    if (!rumorEvent.isValid || !rumorEvent.isSigned) {
      log("GiftWrap rumorEvent sign check result fail, id: ${e.id}, from: ${e.pubkey}");
      return null;
    }

    var sourceText = await nostr!.nostrSigner
        .nip44Decrypt(rumorEvent.pubkey, rumorEvent.content);
    if (sourceText == null) {
      return null;
    }

    var jsonObj = jsonDecode(sourceText);
    return Event.fromJson(jsonObj);
  }

  static Future<Event?> getGiftWrapEvent(
      Event e, Nostr targetNostr, String receiverPublicKey) async {
    var giftEventCreatedAt =
        e.createdAt - math.Random().nextInt(60 * 60 * 24 * 2);
    var rumorEventMap = e.toJson();
    rumorEventMap.remove("sig");

    var sealEventContent = await nostr!.nostrSigner
        .nip44Encrypt(receiverPublicKey, jsonEncode(rumorEventMap));
    if (sealEventContent == null) {
      return null;
    }
    var sealEvent = Event(
        targetNostr.publicKey, EventKind.SEAL_EVENT_KIND, [], sealEventContent);
    targetNostr.signEvent(sealEvent);

    var randomPrivateKey = generatePrivateKey();
    var randomPubkey = getPublicKey(randomPrivateKey);
    var randomKey = NIP44V2.shareSecret(randomPrivateKey, receiverPublicKey);
    var giftWrapEventContent =
        await NIP44V2.encrypt(jsonEncode(sealEvent.toJson()), randomKey);
    var giftWrapEvent = Event(
        randomPubkey,
        EventKind.GIFT_WRAP,
        [
          ["p", receiverPublicKey]
        ],
        giftWrapEventContent,
        publishAt:
            DateTime.fromMillisecondsSinceEpoch(giftEventCreatedAt * 1000));
    giftWrapEvent.sign(randomPrivateKey);

    return giftWrapEvent;
  }
}
