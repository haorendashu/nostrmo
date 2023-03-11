import 'package:convert/convert.dart';
import 'package:nostrmo/client/nip19/hrps.dart';

import 'bech32.dart';

class Nip19 {
  static String encodePubKey(String pubKey) {
    var data = hex.decode(pubKey);
    data = Bech32.convertBits(data, 8, 5, true);
    return Bech32.encode(Hrps.PUBLIC_KEY, data);
  }

  static String encodeSimplePubKey(String pubKey) {
    var code = encodePubKey(pubKey);
    var length = code.length;
    return code.substring(0, 6) + ":" + code.substring(length - 6);
  }

  static Bech32DecodeResult decode(String code) {
    return Bech32.decode(code);
  }
}
