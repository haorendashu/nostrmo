import 'dart:math';

class StringUtil {
  static bool isNotBlank(String? str) {
    if (str != null && str != "") {
      return true;
    }
    return false;
  }

  static bool isBlank(String? str) {
    return !isNotBlank(str);
  }

  static String breakWord(String word) {
    if (word == null || word.isEmpty) {
      return word;
    }
    String breakWord = '';
    word.runes.forEach((element) {
      breakWord += String.fromCharCode(element);
      breakWord += '\u200B';
    });
    return breakWord;
  }

  static List<String> charByChar(String word) {
    // var runes = word.runes;
    // var length = runes.length;
    List<String> letters = [];
    word.runes.forEach((int rune) {
      var character = String.fromCharCode(rune);
      letters.add(character);
    });
    return letters;
  }
}
