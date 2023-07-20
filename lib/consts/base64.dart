import 'dart:convert';
import 'dart:typed_data';

class BASE64 {
  static const String PREFIX = "data:image/png;base64,";

  static bool check(String str) {
    return str.indexOf(PREFIX) == 0;
  }

  static Uint8List toData(String base64Str) {
    return Base64Decoder().convert(base64Str.replaceFirst(PREFIX, ""));
  }

  static String toBase64(Uint8List data) {
    var base64Str = base64Encode(data);
    return "${BASE64.PREFIX}$base64Str";
  }
}
