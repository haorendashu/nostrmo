import 'dart:convert';

import 'package:nostrmo/util/string_util.dart';

import '../signer/nostr_signer.dart';

class NostrRemoteResponse {
  String id;

  String result;

  String? error;

  NostrRemoteResponse(this.id, this.result, {this.error});

  static Future<NostrRemoteResponse?> decrypt(
      String ciphertext, NostrSigner signer, String pubkey) async {
    var plaintext = await signer.decrypt(pubkey, ciphertext);
    if (StringUtil.isNotBlank(plaintext)) {
      // print(plaintext);
      var jsonMap = jsonDecode(plaintext!);

      var id = jsonMap["id"];
      var result = jsonMap["result"];

      if (id != null && id is String && result != null && result is String) {
        return NostrRemoteResponse(id, result, error: jsonMap["error"]);
      }
    }

    return null;
  }
}
