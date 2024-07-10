import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/signer/nostr_signer.dart';
import 'package:nostrmo/util/platform_util.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util';

@JS()
external JSPromise nip07GetPublicKey();

@JS()
external JSPromise nip07GetRelays();

@JS()
external JSPromise nip07Nip04Decrypt(String pubkey, String ciphertext);

@JS()
external JSPromise nip07Nip04Encrypt(String pubkey, String plaintext);

@JS()
external JSPromise nip07Nip44Decrypt(String pubkey, String ciphertext);

@JS()
external JSPromise nip07Nip44Encrypt(String pubkey, String plaintext);

@JS()
external JSPromise nip07SignEvent(String eventStr);

class NIP07Signer extends NostrSigner {
  static String URI_PRE = "websigner";

  static bool isWebNostrSignerKey(String key) {
    if (key.startsWith(URI_PRE)) {
      return true;
    }
    return false;
  }

  static String getPubkey(String key) {
    var strs = key.split(":");
    if (strs.length >= 2) {
      return strs[1];
    }

    return key;
  }

  static bool support() {
    if (PlatformUtil.isWeb()) {
      return js.context.callMethod("nip07Support");
    }
    return false;
  }

  String? _pubkey;

  @override
  Future<String?> getPublicKey() async {
    if (_pubkey != null) {
      return _pubkey!;
    }

    var promise = nip07GetPublicKey();
    var stringResult = await promiseToFuture(promise);
    if (stringResult != null && stringResult is String) {
      _pubkey = stringResult;
    }

    return _pubkey;
  }

  @override
  Future<Map?> getRelays() async {
    var promise = nip07GetRelays();
    var stringResult = await promiseToFuture(promise);
    if (stringResult != null) {
      return jsonDecode(stringResult);
    }

    return null;
  }

  @override
  Future<String?> decrypt(pubkey, ciphertext) async {
    var promise = nip07Nip04Decrypt(pubkey, ciphertext);
    return await promiseToFuture(promise);
  }

  @override
  Future<String?> encrypt(pubkey, plaintext) async {
    var promise = nip07Nip04Decrypt(pubkey, plaintext);
    return await promiseToFuture(promise);
  }

  @override
  Future<String?> nip44Decrypt(pubkey, ciphertext) async {
    var promise = nip07Nip04Decrypt(pubkey, ciphertext);
    return await promiseToFuture(promise);
  }

  @override
  Future<String?> nip44Encrypt(pubkey, plaintext) async {
    var promise = nip07Nip04Decrypt(pubkey, plaintext);
    return await promiseToFuture(promise);
  }

  @override
  Future<Event?> signEvent(Event event) async {
    var promise = nip07SignEvent(jsonEncode(event.toJson()));
    var stringResult = await promiseToFuture(promise);
    if (stringResult != null) {
      return Event.fromJson(jsonDecode(stringResult));
    }

    return null;
  }
}
