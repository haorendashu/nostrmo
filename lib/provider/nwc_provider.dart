import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/nip04/nip04.dart';
import 'package:nostr_sdk/nip47/nwc_info.dart';
import 'package:nostr_sdk/relay/relay.dart';
import 'package:nostr_sdk/relay/relay_base.dart';
import 'package:nostr_sdk/relay/relay_status.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/client_connected.dart';
import 'package:nostrmo/main.dart';
import 'package:pointycastle/impl.dart';

class NWCProvider extends ChangeNotifier {
  Relay? _relay;

  NWCInfo? _nwcInfo;

  ECDHBasicAgreement? agreement;

  void init() {
    var nwcUrl = settingProvider.nwcUrl;
    if (StringUtil.isNotBlank(nwcUrl)) {
      var ni = NWCInfo.loadFromUrl(nwcUrl);
      setNWCInfo(ni);
    }
  }

  void setNWCInfo(NWCInfo? nwcInfo) {
    if (_nwcInfo != null && nwcInfo != null) {
      // has a old nwcInfo, check if it was the same
      if (_nwcInfo!.secret == nwcInfo.secret &&
          _nwcInfo!.relay == nwcInfo.relay &&
          _nwcInfo!.pubkey == nwcInfo.pubkey) {
        // the same, not do anything.
        return;
      }
    }

    _nwcInfo = nwcInfo;
    if (_nwcInfo != null) {
      if (_relay != null) {
        try {
          _relay!.disconnect();
          _relay!.dispose();
          _relay = null;
        } catch (e) {}
      }

      // doConnect
      doConnect();
    }
  }

  void clear() {
    _nwcInfo = null;
    agreement = null;

    if (_relay != null) {
      try {
        _relay!.disconnect();
        _relay!.dispose();
        _relay = null;
      } catch (e) {}
    }
  }

  void doConnect() {
    if (_nwcInfo == null) {
      return;
    }

    agreement = NIP04.getAgreement(_nwcInfo!.secret);

    var relayAddr = _nwcInfo!.relay;
    _relay = RelayBase(relayAddr, RelayStatus(relayAddr));
    log("nwc relay begin to connect");
    _relay!.connect();

    _relay!.onMessage = onMessage;
  }

  bool isConnected() {
    if (_nwcInfo != null && _relay != null) {
      if (_relay!.relayStatus.connected == ClientConneccted.CONNECTED) {
        return true;
      }
    }

    return false;
  }

  void onMessage(Relay relay, List<dynamic> json) {
    var jsonLength = json.length;
    final messageType = json[0];
    if (messageType == 'EVENT' && jsonLength > 2) {
      final event = Event.fromJson(json[2]);
      if (event.kind == EventKind.NWC_RESPONSE_EVENT) {
        var encryptedContent = event.content;
        var sourceConent =
            NIP04.decrypt(encryptedContent, agreement!, _nwcInfo!.pubkey);
        if (StringUtil.isNotBlank(sourceConent)) {
          // response will like this.
          // {
          //  "result_type": "pay_invoice", //indicates the structure of the result field
          //    "error": { //object, non-null in case of error
          //       "code": "UNAUTHORIZED", //string error code, see below
          //       "message": "human readable error message"
          //   },
          //   "result": { // result, object. null in case of error.
          //       "preimage": "0123456789abcdef..." // command-related data
          //   }
          // }
          var msgJsonMap = jsonDecode(sourceConent);
          var error = msgJsonMap["error"];
          if (error != null) {
            // oh no, error found.
            // begin to find the eventId.
            String? eventId;
            for (var tag in event.tags) {
              var tagLength = tag.length;
              if (tagLength > 1) {
                var k = tag[0];
                var v = tag[1];

                if (k == "e") {
                  eventId = v;
                  break;
                }
              }
            }
            if (StringUtil.isNotBlank(eventId)) {
              print("NWC zap fail $eventId");
              print(error);

              // TODO maybe there should do some rollback here.
            }
          }
        }
      }
    } else if (messageType == 'EOSE' && jsonLength > 1) {
      var subscriptionId = json[1];
      relay.send(["CLOSE", subscriptionId]);
    }
  }

  void sendZap(BuildContext context, String invoiceCode) {
    if (_nwcInfo == null || _relay == null) {
      return;
    }

    var payInvoice = {
      "method": "pay_invoice",
      "params": {"invoice": invoiceCode}
    };
    var payInvoiceText = jsonEncode(payInvoice);
    var payInvoiceEncryptedText =
        NIP04.encrypt(payInvoiceText, agreement!, _nwcInfo!.pubkey);

    // gen event
    var payInvoiceEvent = Event(
      _nwcInfo!.senderPubkey(),
      EventKind.NWC_REQUEST_EVENT,
      [
        ["p", _nwcInfo!.pubkey]
      ],
      payInvoiceEncryptedText,
    );
    // sign event
    payInvoiceEvent.sign(_nwcInfo!.secret);
    var eventJsonMap = payInvoiceEvent.toJson();
    log("nwc send zap event: ${jsonEncode(eventJsonMap)}");

    // send invoice
    _relay!.send(["EVENT", eventJsonMap], forceSend: true);

    // query if there is pay_invoice callback
    _relay!.send([
      "REQ",
      StringUtil.rndNameStr(14),
      {
        "#e": [payInvoiceEvent.id],
        "kinds": [EventKind.NWC_RESPONSE_EVENT],
      }
    ]);
  }
}
