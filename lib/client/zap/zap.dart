import 'dart:convert';
import 'dart:developer';

import 'package:bech32/bech32.dart';
import 'package:nostr_dart/nostr_dart.dart';

import '../event_kind.dart' as kind;
import '../../util/dio_util.dart';
import '../../util/string_util.dart';
import '../cust_nostr.dart';
import '../nip19/nip19.dart';
import 'lnurl_response.dart';

class Zap {
  static String decodeLud06Link(String lud06) {
    var decoder = Bech32Decoder();
    var bech32Result = decoder.convert(lud06, 2000);
    var data = Nip19.convertBits(bech32Result.data, 5, 8, false);
    return utf8.decode(data);
  }

  static String? getLnurlFromLud16(String lud16) {
    var strs = lud16.split("@");
    if (strs.length < 2) {
      return null;
    }

    var username = strs[0];
    var domainname = strs[1];

    var link = "https://$domainname/.well-known/lnurlp/$username";
    var data = utf8.encode(link);
    data = Nip19.convertBits(data, 8, 5, true);

    var encoder = Bech32Encoder();
    Bech32 input = Bech32("lnurl", data);
    var lnurl = encoder.convert(input, 2000);

    return lnurl.toUpperCase();
  }

  static Future<LnurlResponse?> getLnurlResponse(String link) async {
    var responseMap = await DioUtil.get(link);
    if (responseMap != null && StringUtil.isNotBlank(responseMap["callback"])) {
      return LnurlResponse.fromJson(responseMap);
    }

    return null;
  }

  static Future<String?> getInvoiceCode({
    required String lnurl,
    required int sats,
    required String recipientPubkey,
    String? eventId,
    required CustNostr targetNostr,
    required List<String> relays,
  }) async {
    var lnurlLink = decodeLud06Link(lnurl);
    var lnurlResponse = await getLnurlResponse(lnurlLink);
    if (lnurlResponse == null) {
      return null;
    }

    var callback = lnurlResponse.callback!;
    if (callback.contains("?")) {
      callback += "&";
    } else {
      callback += "?";
    }

    var amount = sats * 1000;
    callback += "amount=$amount";

    var tags = [
      ["relays", ...relays],
      ["amount", amount.toString()],
      ["lnurl", lnurl],
      ["p", recipientPubkey],
    ];
    if (StringUtil.isNotBlank(eventId)) {
      tags.add(["e", eventId!]);
    }
    var event =
        Event(targetNostr.publicKey, kind.EventKind.ZAP_REQUEST, tags, "");
    event.sign(targetNostr.privateKey);
    var eventStr = Uri.encodeQueryComponent(jsonEncode(event));
    callback += "&nostr=$eventStr";
    callback += "&lnurl=$lnurl";

    log("getInvoice callback $callback");

    var responseMap = await DioUtil.get(callback);
    if (responseMap != null && StringUtil.isNotBlank(responseMap["pr"])) {
      return responseMap["pr"];
    }

    return null;
  }
}
