import 'package:encrypt/encrypt.dart';

class EncryptUtil {
  // AES128 CBC pkcs7padding iv util8 base64
  static String aesEncrypt(String plainText, String keyStr, String ivStr) {
    final key = Key.fromUtf8(keyStr);
    final iv = IV.fromUtf8(ivStr);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return encrypted.base64;
  }

  static String aesEncryptBytes(List<int> input, String keyStr, String ivStr) {
    final key = Key.fromUtf8(keyStr);
    final iv = IV.fromUtf8(ivStr);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(input, iv: iv);

    return encrypted.base64;
  }

  static String aesDecrypt(String str, String keyStr, String ivStr) {
    final key = Key.fromUtf8(keyStr);
    final iv = IV.fromUtf8(ivStr);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final decrypted = encrypter.decrypt64(str, iv: iv);

    return decrypted;
  }
}
