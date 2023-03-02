import 'dart:ui';

import 'package:flutter/material.dart';

class ColorList {
  static List<Color> ALL_COLOR = [
    Colors.purple[700]!,
    Colors.blue[700]!,
    Colors.cyan[700]!,
    // Colors.green[600],
    Color(0xff519495),
    Colors.yellow[700]!,
    Colors.orange[700]!,
    Colors.red[700]!,
  ];

  static MaterialColor getThemeColor(int colorValue) {
    var i = 0;
    Color checkedColor = ALL_COLOR[i++];
    if (colorValue == checkedColor.value) {
      return MaterialColor(
        checkedColor.value,
        <int, Color>{
          50: Color(0xFFF3E5F5),
          100: Color(0xFFE1BEE7),
          200: Color(0xFFCE93D8),
          300: Color(0xFFBA68C8),
          400: Color(0xFFAB47BC),
          500: checkedColor,
          600: Color(0xFF8E24AA),
          700: Color(0xFF7B1FA2),
          800: Color(0xFF6A1B9A),
          900: Color(0xFF4A148C),
        },
      );
    }

    checkedColor = ALL_COLOR[i++];
    if (colorValue == checkedColor.value) {
      return MaterialColor(
        checkedColor.value,
        <int, Color>{
          50: Color(0xFFE3F2FD),
          100: Color(0xFFBBDEFB),
          200: Color(0xFF90CAF9),
          300: Color(0xFF64B5F6),
          400: Color(0xFF42A5F5),
          500: checkedColor,
          600: Color(0xFF1E88E5),
          700: Color(0xFF1976D2),
          800: Color(0xFF1565C0),
          900: Color(0xFF0D47A1),
        },
      );
    }

    checkedColor = ALL_COLOR[i++];
    if (colorValue == checkedColor.value) {
      return MaterialColor(
        checkedColor.value,
        <int, Color>{
          50: Color(0xFFE0F7FA),
          100: Color(0xFFB2EBF2),
          200: Color(0xFF80DEEA),
          300: Color(0xFF4DD0E1),
          400: Color(0xFF26C6DA),
          500: checkedColor,
          600: Color(0xFF00ACC1),
          700: Color(0xFF0097A7),
          800: Color(0xFF00838F),
          900: Color(0xFF006064),
        },
      );
    }

    checkedColor = ALL_COLOR[i++];
    if (colorValue == checkedColor.value) {
      return MaterialColor(
        checkedColor.value,
        <int, Color>{
          50: Color(0xFFE8F5E9),
          100: Color(0xFFC8E6C9),
          200: Color(0xFFA5D6A7),
          300: Color(0xFF81C784),
          400: Color(0xFF66BB6A),
          500: checkedColor,
          600: Color(0xFF43A047),
          700: Color(0xFF388E3C),
          800: Color(0xFF2E7D32),
          900: Color(0xFF1B5E20),
        },
      );
    }

    checkedColor = ALL_COLOR[i++];
    if (colorValue == checkedColor.value) {
      return MaterialColor(
        checkedColor.value,
        <int, Color>{
          50: Color(0xFFFFFDE7),
          100: Color(0xFFFFF9C4),
          200: Color(0xFFFFF59D),
          300: Color(0xFFFFF176),
          400: Color(0xFFFFEE58),
          500: checkedColor,
          600: Color(0xFFFDD835),
          700: Color(0xFFFBC02D),
          800: Color(0xFFF9A825),
          900: Color(0xFFF57F17),
        },
      );
    }

    checkedColor = ALL_COLOR[i++];
    if (colorValue == checkedColor.value) {
      return MaterialColor(
        checkedColor.value,
        <int, Color>{
          50: Color(0xFFFFF3E0),
          100: Color(0xFFFFE0B2),
          200: Color(0xFFFFCC80),
          300: Color(0xFFFFB74D),
          400: Color(0xFFFFA726),
          500: checkedColor,
          600: Color(0xFFFB8C00),
          700: Color(0xFFF57C00),
          800: Color(0xFFEF6C00),
          900: Color(0xFFE65100),
        },
      );
    }

    checkedColor = ALL_COLOR[i++];
    if (colorValue == checkedColor.value) {
      return MaterialColor(
        checkedColor.value,
        <int, Color>{
          50: Color(0xFFFFEBEE),
          100: Color(0xFFFFCDD2),
          200: Color(0xFFEF9A9A),
          300: Color(0xFFE57373),
          400: Color(0xFFEF5350),
          500: checkedColor,
          600: Color(0xFFE53935),
          700: Color(0xFFD32F2F),
          800: Color(0xFFC62828),
          900: Color(0xFFB71C1C),
        },
      );
    }

    // Default
    return MaterialColor(
      checkedColor.value,
      <int, Color>{
        50: Color(0xFFE8F5E9),
        100: Color(0xFFC8E6C9),
        200: Color(0xFFA5D6A7),
        300: Color(0xFF81C784),
        400: Color(0xFF66BB6A),
        500: checkedColor,
        600: Color(0xFF43A047),
        700: Color(0xFF388E3C),
        800: Color(0xFF2E7D32),
        900: Color(0xFF1B5E20),
      },
    );
  }
}
