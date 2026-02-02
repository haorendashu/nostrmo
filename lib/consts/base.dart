import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nostrmo/util/hash_util.dart';

class Base {
  static const APP_NAME = "Nostrmo";

  static String VERSION_NAME = "3.5.0";

  static int VERSION_NUM = 1;

  static const String PRIVACY_LINK =
      "https://nostrmo.com/pages/PolicyAndTerms.html";

  static const double BASE_PADDING = 12;

  static const double BASE_PADDING_HALF = 6;

  static String INDEXS_EVENTS = "https://nostrmo.com/indexs/events.json";

  static String INDEXS_CONTACTS = "https://nostrmo.com/indexs/contacts.json";

  static String INDEXS_TOPICS = "https://nostrmo.com/indexs/topics.json";

  static String INDEXS_STARTER_PACKS =
      "https://nostrmo.com/indexs/starterpacks.json";

  static String INDEXS_RELAYS = "https://nostrmo.com/indexs/relays.json";

  static String WEB_TOOLS = "https://nostrmo.com/indexs/webtools.json";

  static String IMAGE_PROXY_SERVICE = "https://imagebridge.nostrmo.com/";

  static String IMAGE_PROXY_SERVICE_KEY = "please_do_not_abuse_thanks";

  static String userAgent() {
    return "$APP_NAME $VERSION_NAME";
  }

  static String KEY_EKEY = HashUtil.md5("Jo49KwLvyhrsar");

  static String KEY_IV = "1681713832000000";

  static double BASE_FONT_SIZE = 16;

  static double BASE_FONT_SIZE_PC = 16;

  static double TABBAR_HEIGHT = 46;

  static int DEFAULT_DATA_INDEX = -1;

  static Color BTC_COLOR = Colors.orange;
}
