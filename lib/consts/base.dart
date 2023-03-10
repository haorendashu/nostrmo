import 'dart:ui';

class Base {
  static const APP_NAME = "Nostrmo";

  static String VERSION_NAME = "1.0.0";

  static int VERSION_NUM = 1;

  static const String PRIVACY_LINK =
      "https://nostrmo.mizhichashao.com/pages/PolicyAndTerms.html";

  static const double BASE_PADDING = 12;

  static const double BASE_PADDING_HALF = 6;

  static String userAgent() {
    return "$APP_NAME $VERSION_NAME";
  }
}
