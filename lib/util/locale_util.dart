import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/string_util.dart';

class LocaleUtil {
  static String getLocaleKey(Locale l) {
    var key = l.languageCode;
    if (StringUtil.isNotBlank(l.countryCode)) {
      key += "_" + l.countryCode!;
    }
    return key;
  }

  static String? genLocaleKeyFromSring(String? i18n, String? i18nCC) {
    var key = i18n;
    if (StringUtil.isNotBlank(key) && StringUtil.isNotBlank(i18nCC)) {
      key = key! + "_" + i18nCC!;
    }
    return key;
  }
}
