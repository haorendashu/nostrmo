import 'package:bech32/bech32.dart';
import 'package:hex/hex.dart';
import 'package:nostrmo/client/nip19/hrps.dart';

class Nip19 {
  // static String encodePubKey(String pubKey) {
  //   var data = hex.decode(pubKey);
  //   data = Bech32.convertBits(data, 8, 5, true);
  //   return Bech32.encode(Hrps.PUBLIC_KEY, data);
  // }
  static String encodePubKey(String pubKey) {
    var data = HEX.decode(pubKey);
    data = _convertBits(data, 8, 5, true);

    var encoder = Bech32Encoder();
    Bech32 input = Bech32(Hrps.PUBLIC_KEY, data);
    return encoder.convert(input);
  }

  static String encodeSimplePubKey(String pubKey) {
    var code = encodePubKey(pubKey);
    var length = code.length;
    return code.substring(0, 6) + ":" + code.substring(length - 6);
  }

  // static String decode(String npub) {
  //   var res = Bech32.decode(npub);
  //   var data = Bech32.convertBits(res.words, 5, 8, false);
  //   return hex.encode(data).substring(0, 64);
  // }
  static String decodePubKey(String npub) {
    var decoder = Bech32Decoder();
    var bech32Result = decoder.convert(npub);
    var data = _convertBits(bech32Result.data, 5, 8, false);
    return HEX.encode(data);
  }

  static List<int> _convertBits(List<int> data, int from, int to, bool pad) {
    var acc = 0;
    var bits = 0;
    var result = <int>[];
    var maxv = (1 << to) - 1;

    data.forEach((v) {
      if (v < 0 || (v >> from) != 0) {
        throw Exception();
      }
      acc = (acc << from) | v;
      bits += from;
      while (bits >= to) {
        bits -= to;
        result.add((acc >> bits) & maxv);
      }
    });

    if (pad) {
      if (bits > 0) {
        result.add((acc << (to - bits)) & maxv);
      }
    } else if (bits >= from) {
      throw InvalidPadding('illegal zero padding');
    } else if (((acc << (to - bits)) & maxv) != 0) {
      throw InvalidPadding('non zero');
    }

    return result;
  }
}
