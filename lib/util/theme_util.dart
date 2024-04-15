// Add some support to get value from theme data.
import 'package:flutter/material.dart';

class ThemeUtil {
  static Color getDialogCoverColor(ThemeData themeData) {
    return (themeData.textTheme.bodyMedium!.color ?? Colors.black)
        .withOpacity(0.2);
  }
}
