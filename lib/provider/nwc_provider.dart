import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
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

import '../data/nwc_transaction.dart';

class NWCProvider extends ChangeNotifier {
  Relay? _relay;

  NWCInfo? _nwcInfo;

  ECDHBasicAgreement? agreement;

  int balance = 0;

  String? lud16() {
    if (_nwcInfo != null) {
      return _nwcInfo!.lud16;
    }

    return null;
  }

  void reload() {
    var nwcUrl = settingProvider.nwcUrl;
    if (StringUtil.isNotBlank(nwcUrl)) {
      var ni = NWCInfo.loadFromUrl(nwcUrl);
      setNWCInfo(ni);
    } else {
      // nwc not set, clear it.
      if (_nwcInfo != null) {
        clear();
      }
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
    _relay!.connect().then((connected) {
      if (connected) {
        update();
      }

      notifyListeners();
    });

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
    var subscriptionId = json[1];
    if (messageType == 'EVENT' && jsonLength > 2) {
      final event = Event.fromJson(json[2]);
      // print(event);
      if (event.kind == EventKind.NWC_RESPONSE_EVENT) {
        var encryptedContent = event.content;
        var sourceConent =
            NIP04.decrypt(encryptedContent, agreement!, _nwcInfo!.pubkey);
        if (StringUtil.isNotBlank(sourceConent)) {
          // response will like this.
          // {
          //   "result_type": "pay_invoice", //indicates the structure of the result field
          //   "error": { //object, non-null in case of error
          //       "code": "UNAUTHORIZED", //string error code, see below
          //       "message": "human readable error message"
          //   },
          //   "result": { // result, object. null in case of error.
          //       "preimage": "0123456789abcdef..." // command-related data
          //   }
          // }
          var msgJsonMap = jsonDecode(sourceConent);

          var completer = _callbacks[subscriptionId];
          if (completer != null) {
            completer.complete(msgJsonMap);
            return;
          }

          // // print(msgJsonMap);
          // var error = msgJsonMap["error"];
          // if (error != null) {
          //   // oh no, error found.
          //   // begin to find the eventId.
          //   String? eventId;
          //   for (var tag in event.tags) {
          //     var tagLength = tag.length;
          //     if (tagLength > 1) {
          //       var k = tag[0];
          //       var v = tag[1];

          //       if (k == "e") {
          //         eventId = v;
          //         break;
          //       }
          //     }
          //   }
          //   if (StringUtil.isNotBlank(eventId)) {
          //     print("NWC zap fail $eventId");
          //     print(error);

          //     // TODO maybe there should do some rollback here.
          //   }
          // } else {
          //   // success
          //   var result = msgJsonMap["result"];
          //   if (result != null) {
          //     var resultType = msgJsonMap["result_type"];
          //     if (resultType == "pay_invoice") {
          //       // pay_invoice
          //     } else if (resultType == "get_info") {
          //       // get_info
          //       // {
          //       //  "result_type": "get_info",
          //       //  "result": {
          //       //        "alias": "string",
          //       //        "color": "hex string",
          //       //        "pubkey": "hex string",
          //       //        "network": "string", // mainnet, testnet, signet, or regtest
          //       //        "block_height": 1,
          //       //        "block_hash": "hex string",
          //       //        "methods": ["pay_invoice", "get_balance", "make_invoice", "lookup_invoice", "list_transactions", "get_info"], // list of supported methods for this connection
          //       //        "notifications": ["payment_received", "payment_sent"], // list of supported notifications for this connection, optional.
          //       //  }
          //       notifyListeners();
          //     } else if (resultType == "get_balance") {
          //       // get_balance
          //       // {
          //       //  "result_type": "get_balance",
          //       //  "result": {
          //       //      "balance": 10000, // user's balance in msats
          //       //  }
          //       // }
          //       var b = result["balance"];
          //       if (b != null) {
          //         balance = ((b / 1000) as double).toInt();
          //         notifyListeners();
          //       }
          //     } else if (resultType == "pay_invoice") {
          //       updateBalance();
          //     } else if (resultType == "list_transactions") {
          //       var transactions = result["transactions"];
          //       var onTransactions = _onTransactionsMap[subscriptionId];
          //       _onTransactionsMap.remove(subscriptionId);
          //       if (transactions != null &&
          //           transactions is List &&
          //           onTransactions != null) {
          //         List<NwcTransaction> list = [];
          //         for (var transactionMap in transactions) {
          //           // log(jsonEncode(transactionMap));
          //           var transaction = NwcTransaction.fromJson(transactionMap);
          //           list.add(transaction);
          //         }

          //         onTransactions(list);
          //       }
          //     }
          //   }
          // }
        }
      }
    } else if (messageType == 'EOSE' && jsonLength > 1) {
      var subscriptionId = json[1];
      relay.send(["CLOSE", subscriptionId]);
    }
  }

  Map<String, Completer<Map<String, dynamic>?>> _callbacks = {};

  Future<bool> sendZap(BuildContext context, String invoiceCode) async {
    if (_nwcInfo == null || _relay == null) {
      return false;
    }

    var payInvoice = {
      "method": "pay_invoice",
      "params": {"invoice": invoiceCode}
    };

    var msgJsonMap = await _sendRequest(payInvoice);
    var result = checkAndGetResult(msgJsonMap, "pay_invoice");
    if (result != null) {
      return true;
    }

    return false;
  }

  void update() {
    updateBalance();
    updateInfo();
  }

  Future<void> updateBalance() async {
    var getBalance = {"method": "get_balance", "params": {}};
    var msgJsonMap = await _sendRequest(getBalance);
    var result = checkAndGetResult(msgJsonMap, "get_balance");
    if (result != null) {
      var b = result["balance"];
      if (b != null) {
        balance = ((b / 1000) as double).toInt();
        notifyListeners();
      }
    }
  }

  Future<void> updateInfo() async {
    var getBalance = {"method": "get_info", "params": {}};
    var msgJsonMap = await _sendRequest(getBalance);
    var result = checkAndGetResult(msgJsonMap, "get_info");
    if (result != null) {
      // ????
    }
  }

  Future<List<NwcTransaction>?> queryTransactions(
      {int? until, int limit = 50}) async {
    var reqeustArgs = {
      "method": "list_transactions",
      "params": {
        "until": until,
        "limit": limit,
      }
    };
    var msgJsonMap = await _sendRequest(reqeustArgs);
    var result = checkAndGetResult(msgJsonMap, "list_transactions");
    if (result != null) {
      var transactions = result["transactions"];
      if (transactions != null && transactions is List) {
        List<NwcTransaction> list = [];
        for (var transactionMap in transactions) {
          // log(jsonEncode(transactionMap));
          var transaction = NwcTransaction.fromJson(transactionMap);
          list.add(transaction);
        }

        return list;
      }
    }

    return null;
  }

  Map<String, dynamic>? checkAndGetResult(
      Map<String, dynamic>? msgJsonMap, String resultTyp) {
    if (msgJsonMap != null) {
      var error = msgJsonMap["error"];
      if (error != null) {
        BotToast.showText(text: jsonEncode(error));
        return null;
      }

      var resultType = msgJsonMap["result_type"];
      if (error == null && resultType == resultTyp) {
        return msgJsonMap["result"];
      }
    }

    return null;
  }

  Future<Map<String, dynamic>?> _sendRequest(Map<String, dynamic> params,
      {String? subscriptionId}) async {
    var paramsText = jsonEncode(params);
    // log("nwc request params: $paramsText");
    var paramsEncryptedText =
        NIP04.encrypt(paramsText, agreement!, _nwcInfo!.pubkey);

    // gen event
    var event = Event(
      _nwcInfo!.senderPubkey(),
      EventKind.NWC_REQUEST_EVENT,
      [
        ["p", _nwcInfo!.pubkey]
      ],
      paramsEncryptedText,
    );
    // sign event
    event.sign(_nwcInfo!.secret);
    var eventJsonMap = event.toJson();
    // log("nwc send request event: ${jsonEncode(eventJsonMap)}");

    // send invoice
    _relay!.send(["EVENT", eventJsonMap], forceSend: true);

    subscriptionId ??= StringUtil.rndNameStr(14);
    var completer = Completer<Map<String, dynamic>?>();
    _callbacks[subscriptionId] = completer;

    _relay!.send([
      "REQ",
      subscriptionId,
      {
        "#e": [event.id],
        "kinds": [EventKind.NWC_RESPONSE_EVENT],
      }
    ]);

    return await completer.future;
  }
}
