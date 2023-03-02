import 'package:flutter/material.dart';

class ColorsUtil {
  /// 十六进制颜色，
  /// hex, 十六进制值，例如：0xffffff,
  /// alpha, 透明度 [0.0,1.0]
  static Color hexColor(int hex, {double alpha = 1}) {
    if (alpha < 0) {
      alpha = 0;
    } else if (alpha > 1) {
      alpha = 1;
    }
    return Color.fromRGBO((hex & 0xFF0000) >> 16, (hex & 0x00FF00) >> 8,
        (hex & 0x0000FF) >> 0, alpha);
  }

  static Color hexToColor(String s) {
    // 如果传入的十六进制颜色值不符合要求，返回默认值
    if (s.length != 7 || int.tryParse(s.substring(1, 7), radix: 16) == null) {
      s = '#999999';
    }

    return new Color(int.parse(s.substring(1, 7), radix: 16) + 0xFF000000);
  }

  static String colorToHex(Color color) {
    return "#" +
        color.red.toRadixString(16) +
        color.green.toRadixString(16) +
        color.blue.toRadixString(16);
  }
}
