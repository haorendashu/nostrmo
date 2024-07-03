import 'package:nostrmo/client/client_utils/keys.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/util/string_util.dart';

class NostrRemoteSignerInfo {
  String remoteUserPubkey;

  List<String> relays;

  String? optionalSecret;

  String nsec;

  NostrRemoteSignerInfo({
    required this.remoteUserPubkey,
    required this.relays,
    this.optionalSecret,
    required this.nsec,
  });

  @override
  String toString() {
    Map<String, dynamic> pars = {};
    pars["relay"] = relays;
    pars["secret"] = optionalSecret;
    pars["nsec"] = nsec;

    var uri = Uri(
      scheme: "bunker",
      host: remoteUserPubkey,
      queryParameters: pars,
    );

    return uri.toString();
  }

  static bool isBunkerUrl(String? bunkerUrlText) {
    if (bunkerUrlText != null) {
      return bunkerUrlText.startsWith("bunker://");
    }

    return false;
  }

  static NostrRemoteSignerInfo? parseBunkerUrl(String bunkerUrlText,
      {String? nsec}) {
    var uri = Uri.parse(bunkerUrlText);

    var pars = uri.queryParametersAll;

    var remoteUserPubkey = uri.host;

    var relays = pars["relay"];
    if (relays == null || relays.isEmpty) {
      return null;
    }

    var optionalSecrets = pars["secret"];
    String? optionalSecret;
    if (optionalSecrets != null && optionalSecrets.isNotEmpty) {
      optionalSecret = optionalSecrets.first;
    }

    if (StringUtil.isBlank(nsec)) {
      if (pars["nsec"] != null && pars["nsec"]!.isNotEmpty) {
        nsec = pars["nsec"]!.first;
      } else {
        nsec = Nip19.encodePrivateKey(generatePrivateKey());
      }
    }

    return NostrRemoteSignerInfo(
      remoteUserPubkey: remoteUserPubkey,
      relays: relays,
      optionalSecret: optionalSecret,
      nsec: nsec!,
    );
  }
}
