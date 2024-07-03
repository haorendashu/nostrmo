import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/client/nip46/nostr_remote_request.dart';
import 'package:nostrmo/client/nip46/nostr_remote_response.dart';
import 'package:nostrmo/client/signer/local_nostr_signer.dart';
import 'package:nostrmo/client/signer/nostr_signer.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_util.dart';

import '../../consts/client_connected.dart';
import '../../consts/relay_mode.dart';
import '../../data/relay_status.dart';
import '../filter.dart';
import '../relay/relay.dart';
import '../relay/relay_base.dart';
import '../relay/relay_isolate.dart';
import 'nostr_remote_signer_info.dart';

class NostrRemoteSigner extends NostrSigner {
  NostrRemoteSignerInfo info;

  late LocalNostrSigner localNostrSigner;

  NostrRemoteSigner(
    this.info,
  );

  List<Relay> relays = [];

  Map<String, Completer<String?>> callbacks = {};

  Future<void> connect() async {
    localNostrSigner = LocalNostrSigner(Nip19.decode(info.nsec));

    for (var remoteRelayAddr in info.relays) {
      var relay = await _connectToRelay(remoteRelayAddr);
      relays.add(relay);
    }

    var request = NostrRemoteRequest("connect", [
      info.remoteUserPubkey,
      info.optionalSecret ?? "",
      "sign_event,get_relays,get_public_key,nip04_encrypt,nip04_decrypt,nip44_encrypt,nip44_decrypt"
    ]);
    // send connect but not await this request.
    sendAndWaitForResult(request);
  }

  Future<void> onMessage(Relay relay, List<dynamic> json) async {
    final messageType = json[0];
    if (messageType == 'EVENT') {
      try {
        // print(jsonEncode(json[2]));
        // add some statistics
        relay.relayStatus.noteReceive();

        final event = Event.fromJson(json[2]);
        if (event.kind == EventKind.NOSTR_REMOTE_SIGNING) {
          var response = await NostrRemoteResponse.decrypt(
              event.content, localNostrSigner, event.pubkey);
          if (response != null) {
            // don't display here, need user to tap the auth on it's signer app.
            // if (response.result == "auth_url" &&
            //     StringUtil.isNotBlank(response.error)) {
            //   BotToast.showSimpleNotification(
            //       title:
            //           "Tap and copy this to link to auth permissions: \n ${response.error}",
            //       onTap: () {
            //         Clipboard.setData(ClipboardData(text: response.error!))
            //             .then((_) {});
            //       },
            //       duration: const Duration(seconds: 30));
            // }
            var completer = callbacks.remove(response.id);
            if (completer != null) {
              // print("result ${response.result}");
              completer.complete(response.result);
            }
          }
        }
      } catch (err) {
        log(err.toString());
      }
    } else if (messageType == 'EOSE') {
      // ignore EOSE
    } else if (messageType == "NOTICE") {
    } else if (messageType == "AUTH") {}
  }

  Future<Relay> _connectToRelay(String relayAddr) async {
    RelayStatus relayStatus = RelayStatus(relayAddr);
    Relay? relay;
    if (settingProvider.relayMode == RelayMode.BASE_MODE) {
      relay = RelayBase(
        relayAddr,
        relayStatus,
      );
    } else {
      relay = RelayIsolate(
        relayAddr,
        relayStatus,
      );
    }
    relay.onMessage = onMessage;
    addPenddingQueryMsg(relay);
    relay.relayStatusCallback = () {
      if (relayStatus.connected == ClientConneccted.UN_CONNECT) {
        if (relay!.pendingMessages.isEmpty) {
          addPenddingQueryMsg(relay);
        }
      }
    };

    await relay.connect();

    return relay;
  }

  Future<void> addPenddingQueryMsg(Relay relay) async {
    // add a query event
    var queryMsg = await genQueryMsg();
    if (queryMsg != null) {
      relay.pendingMessages.add(queryMsg);
    }
  }

  Future<List?> genQueryMsg() async {
    var pubkey = await localNostrSigner.getPublicKey();
    if (pubkey == null) {
      return null;
    }
    var filter = Filter(
      since: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      p: [pubkey],
      kinds: [EventKind.NOSTR_REMOTE_SIGNING],
    );
    List<dynamic> queryMsg = ["REQ", StringUtil.rndNameStr(12)];
    queryMsg.add(filter.toJson());

    return queryMsg;
  }

  Future<String?> sendAndWaitForResult(NostrRemoteRequest request) async {
    var senderPubkey = await localNostrSigner.getPublicKey();
    var content =
        await request.encrypt(localNostrSigner, info.remoteUserPubkey);
    if (StringUtil.isNotBlank(senderPubkey) && content != null) {
      Event? event = Event(senderPubkey!, EventKind.NOSTR_REMOTE_SIGNING,
          [getRemotePubkeyTags()], content);
      event = await localNostrSigner.signEvent(event);
      if (event != null) {
        var json = ["EVENT", event.toJson()];
        // print(jsonEncode(json));

        // set completer to callbacks
        var completer = Completer<String?>();
        callbacks[request.id] = completer;

        for (var relay in relays) {
          relay.send(json, forceSend: true);
        }

        return await completer.future.timeout(Duration(seconds: 10));
      }
    }
    return null;
  }

  @override
  Future<String?> decrypt(pubkey, ciphertext) async {
    var request = NostrRemoteRequest("nip04_decrypt", [pubkey, ciphertext]);
    return await sendAndWaitForResult(request);
  }

  @override
  Future<String?> encrypt(pubkey, plaintext) async {
    var request = NostrRemoteRequest("nip04_encrypt", [pubkey, plaintext]);
    return await sendAndWaitForResult(request);
  }

  @override
  Future<String?> getPublicKey() async {
    return info.remoteUserPubkey;
  }

  @override
  Future<Map?> getRelays() async {
    var request = NostrRemoteRequest("get_relays", []);
    var result = await sendAndWaitForResult(request);
    if (StringUtil.isNotBlank(result)) {
      return jsonDecode(result!);
    }
    return null;
  }

  @override
  Future<String?> nip44Decrypt(pubkey, ciphertext) async {
    var request = NostrRemoteRequest("nip44_decrypt", [pubkey, ciphertext]);
    return await sendAndWaitForResult(request);
  }

  @override
  Future<String?> nip44Encrypt(pubkey, plaintext) async {
    var request = NostrRemoteRequest("nip44_encrypt", [pubkey, plaintext]);
    return await sendAndWaitForResult(request);
  }

  @override
  Future<Event?> signEvent(Event event) async {
    var eventJsonMap = event.toJson();
    eventJsonMap.remove("id");
    eventJsonMap.remove("pubkey");
    eventJsonMap.remove("sig");
    var eventJsonText = jsonEncode(eventJsonMap);
    // print("eventJsonText");
    // print(eventJsonText);
    var request = NostrRemoteRequest("sign_event", [eventJsonText]);
    var result = await sendAndWaitForResult(request);
    if (StringUtil.isNotBlank(result)) {
      // print("signEventResult");
      // print(result);
      var eventMap = jsonDecode(result!);
      return Event.fromJson(eventMap);
    }

    return null;
  }

  List<String>? _remotePubkeyTags;

  List<String> getRemotePubkeyTags() {
    _remotePubkeyTags ??= ["p", info.remoteUserPubkey];
    return _remotePubkeyTags!;
  }
}
