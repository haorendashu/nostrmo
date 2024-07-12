import 'dart:convert';

import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/client/signer/nostr_signer.dart';
import 'package:synchronized/synchronized.dart';

import '../android_plugin/android_plugin.dart';
import '../android_plugin/android_plugin_activity_result.dart';
import '../android_plugin/android_plugin_intent.dart';

class AndroidNostrSigner implements NostrSigner {
  static const String URI_PRE = "nostrsigner";

  static const String ACTION_VIEW = "android.intent.action.VIEW";

  static bool isAndroidNostrSignerKey(String key) {
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

  AndroidNostrSigner({String? pubkey}) {
    _pubkey = pubkey;
    if (pubkey != null) {
      _npub = Nip19.encodePubKey(pubkey);
    }
  }

  var _lock = new Lock();

  Duration TIMEOUT = const Duration(seconds: 300);

  String? _pubkey;

  String? _npub;

  @override
  Future<String?> decrypt(pubkey, ciphertext) async {
    var intent = AndroidPluginIntent();
    intent.setAction(ACTION_VIEW);
    intent.setData("$URI_PRE:$ciphertext");

    intent.putExtra("type", "nip04_decrypt");
    intent.putExtra("current_user", _npub);
    intent.putExtra("pubKey", pubkey);

    // var result =
    //     await _lock.synchronized<AndroidPluginActivityResult?>(() async {
    //   return await AndroidPlugin.startForResult(intent);
    // }, timeout: TIMEOUT);
    var result = await AndroidPlugin.startForResult(intent);
    if (result != null) {
      var signature = result.data.getExtra("signature");
      if (signature != null && signature is String) {
        // print(signature);
        return signature;
      }
    }

    return null;
  }

  @override
  Future<String?> encrypt(pubkey, plaintext) async {
    var intent = AndroidPluginIntent();
    intent.setAction(ACTION_VIEW);
    intent.setData("$URI_PRE:$plaintext");

    intent.putExtra("type", "nip04_encrypt");
    intent.putExtra("current_user", _npub);
    intent.putExtra("pubKey", pubkey);

    // var result =
    //     await _lock.synchronized<AndroidPluginActivityResult?>(() async {
    //   return await AndroidPlugin.startForResult(intent);
    // }, timeout: TIMEOUT);
    var result = await AndroidPlugin.startForResult(intent);
    if (result != null) {
      var signature = result.data.getExtra("signature");
      if (signature != null && signature is String) {
        return signature;
      }
    }

    return null;
  }

  @override
  Future<String?> getPublicKey() async {
    if (_pubkey != null) {
      return _pubkey;
    }

    List<Map<String, dynamic>> permissions = [];
    permissions.add({'type': 'sign_event', 'kind': 22242});
    permissions.add({'type': 'nip04_encrypt'});
    permissions.add({'type': 'nip44_encrypt'});
    permissions.add({'type': 'nip04_decrypt'});
    permissions.add({'type': 'nip44_decrypt'});
    permissions.add({'type': 'get_public_key'});

    var intent = AndroidPluginIntent();
    intent.setAction(ACTION_VIEW);
    intent.setData("$URI_PRE:");

    intent.putExtra("type", "get_public_key");
    intent.putExtra("permissions", jsonEncode(permissions));

    // var result =
    //     await _lock.synchronized<AndroidPluginActivityResult?>(() async {
    //   return await AndroidPlugin.startForResult(intent);
    // }, timeout: TIMEOUT);
    var result = await AndroidPlugin.startForResult(intent);
    if (result != null) {
      var signature = result.data.getExtra("signature");
      if (signature != null && signature is String) {
        if (Nip19.isPubkey(signature)) {
          // npub
          _npub = signature;
          _pubkey = Nip19.decode(signature);
        } else {
          // hex pubkey
          _pubkey = signature;
          _npub = Nip19.encodePubKey(signature);
        }
        return _pubkey;
      }
    }

    return null;
  }

  @override
  Future<Map?> getRelays() async {
    // TODO: implement getRelays
    throw UnimplementedError();
  }

  @override
  Future<String?> nip44Decrypt(pubkey, ciphertext) async {
    var intent = AndroidPluginIntent();
    intent.setAction(ACTION_VIEW);
    intent.setData("$URI_PRE:$ciphertext");

    intent.putExtra("type", "nip44_decrypt");
    intent.putExtra("current_user", _npub);
    intent.putExtra("pubKey", pubkey);

    // var result =
    //     await _lock.synchronized<AndroidPluginActivityResult?>(() async {
    //   return await AndroidPlugin.startForResult(intent);
    // }, timeout: TIMEOUT);
    var result = await AndroidPlugin.startForResult(intent).timeout(TIMEOUT);
    if (result != null) {
      var signature = result.data.getExtra("signature");
      if (signature != null && signature is String) {
        return signature;
      }
    }

    return null;
  }

  @override
  Future<String?> nip44Encrypt(pubkey, plaintext) async {
    var intent = AndroidPluginIntent();
    intent.setAction(ACTION_VIEW);
    intent.setData("$URI_PRE:$plaintext");

    intent.putExtra("type", "nip44_encrypt");
    intent.putExtra("current_user", _npub);
    intent.putExtra("pubKey", pubkey);

    // var result =
    //     await _lock.synchronized<AndroidPluginActivityResult?>(() async {
    //   return await AndroidPlugin.startForResult(intent);
    // }, timeout: TIMEOUT);
    var result = await AndroidPlugin.startForResult(intent);
    if (result != null) {
      var signature = result.data.getExtra("signature");
      if (signature != null && signature is String) {
        return signature;
      }
    }

    return null;
  }

  @override
  Future<Event?> signEvent(Event event) async {
    var eventMap = event.toJson();
    eventMap.remove("sig");
    var eventJson = jsonEncode(eventMap);

    var intent = AndroidPluginIntent();
    intent.setAction(ACTION_VIEW);
    intent.setData("$URI_PRE:$eventJson");

    intent.putExtra("type", "sing_event");
    intent.putExtra("current_user", _npub);
    intent.putExtra("id", event.id);

    // var result =
    //     await _lock.synchronized<AndroidPluginActivityResult?>(() async {
    //   return await AndroidPlugin.startForResult(intent);
    // }, timeout: TIMEOUT);
    var result = await AndroidPlugin.startForResult(intent);
    if (result != null) {
      var signature = result.data.getExtra("signature");
      if (signature != null && signature is String) {
        event.sig = signature;
        return event;
      }
    }

    return null;
  }
}
