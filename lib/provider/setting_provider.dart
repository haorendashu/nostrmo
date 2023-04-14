import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../consts/base_consts.dart';
import '../consts/theme_style copy.dart';
import '../util/string_util.dart';
import 'data_util.dart';

class SettingProvider extends ChangeNotifier {
  static SettingProvider? _settingProvider;

  SharedPreferences? _sharedPreferences;

  SettingData? _settingData;

  Map<String, String> _privateKeyMap = {};

  static Future<SettingProvider> getInstance() async {
    if (_settingProvider == null) {
      _settingProvider = SettingProvider();
      _settingProvider!._sharedPreferences = await DataUtil.getInstance();
      await _settingProvider!._init();
      _settingProvider!._reloadTranslateSourceArgs();
    }
    return _settingProvider!;
  }

  Future<void> _init() async {
    String? settingStr = _sharedPreferences!.getString(DataKey.SETTING);
    if (StringUtil.isNotBlank(settingStr)) {
      var jsonMap = json.decode(settingStr!);
      if (jsonMap != null) {
        var setting = SettingData.fromJson(jsonMap);
        _settingData = setting;
        _privateKeyMap.clear();
        if (StringUtil.isNotBlank(_settingData!.privateKeyMap)) {
          try {
            var jsonKeyMap = jsonDecode(_settingData!.privateKeyMap!);
            if (jsonKeyMap != null) {
              for (var entry in (jsonKeyMap as Map<String, dynamic>).entries) {
                _privateKeyMap[entry.key] = entry.value;
              }
            }
          } catch (e) {
            log("_settingData!.privateKeyMap! jsonDecode error");
            log(e.toString());
          }
        }
        return;
      }
    }

    _settingData = SettingData();
  }

  Future<void> reload() async {
    await _init();
    _settingProvider!._reloadTranslateSourceArgs();
    notifyListeners();
  }

  Map<String, String> get privateKeyMap => _privateKeyMap;

  String? get privateKey {
    if (_settingData!.privateKeyIndex != null &&
        _settingData!.privateKeyMap != null &&
        _privateKeyMap.isNotEmpty) {
      return _privateKeyMap[_settingData!.privateKeyIndex.toString()];
    }
    return null;
  }

  int addAndChangePrivateKey(String pk, {bool updateUI = false}) {
    int? findIndex;
    var entries = _privateKeyMap.entries;
    for (var entry in entries) {
      if (entry.value == pk) {
        findIndex = int.tryParse(entry.key);
        break;
      }
    }
    if (findIndex != null) {
      privateKeyIndex = findIndex;
      return findIndex;
    }

    for (var i = 0; i < 20; i++) {
      var index = i.toString();
      var _pk = _privateKeyMap[index];
      if (_pk == null) {
        _privateKeyMap[index] = pk;

        _settingData!.privateKeyIndex = i;

        _settingData!.privateKeyMap = json.encode(_privateKeyMap);
        saveAndNotifyListeners(updateUI: updateUI);

        return i;
      }
    }

    return -1;
  }

  void removeKey(int index) {
    var indexStr = index.toString();
    _privateKeyMap.remove(indexStr);
    _settingData!.privateKeyMap = json.encode(_privateKeyMap);
    if (_settingData!.privateKeyIndex == index) {
      if (_privateKeyMap.isEmpty) {
        _settingData!.privateKeyIndex = null;
      } else {
        // find a index
        var keyIndex = _privateKeyMap.keys.first;
        _settingData!.privateKeyIndex = int.tryParse(keyIndex);
      }
    }

    saveAndNotifyListeners();
  }

  SettingData get settingData => _settingData!;

  int? get privateKeyIndex => _settingData!.privateKeyIndex;

  // String? get privateKeyMap => _settingData!.privateKeyMap;

  /// open lock
  int get lockOpen => _settingData!.lockOpen;

  int? get defaultIndex => _settingData!.defaultIndex;

  int? get defaultTab => _settingData!.defaultTab;

  int get linkPreview => _settingData!.linkPreview != null
      ? _settingData!.linkPreview!
      : OpenStatus.OPEN;

  int get videoPreviewInList => _settingData!.videoPreviewInList != null
      ? _settingData!.videoPreviewInList!
      : OpenStatus.CLOSE;

  String? get network => _settingData!.network;

  String? get imageService => _settingData!.imageService;

  int? get videoPreview => _settingData!.videoPreview ?? OpenStatus.CLOSE;

  int? get imagePreview => _settingData!.imagePreview ?? OpenStatus.CLOSE;

  /// i18n
  String? get i18n => _settingData!.i18n;

  String? get i18nCC => _settingData!.i18nCC;

  /// image compress
  int get imgCompress => _settingData!.imgCompress;

  /// theme style
  int get themeStyle => _settingData!.themeStyle;

  /// theme color
  int? get themeColor => _settingData!.themeColor;

  /// fontFamily
  String? get fontFamily => _settingData!.fontFamily;

  int? get openTranslate => _settingData!.openTranslate;

  static const ALL_SUPPORT_LANGUAGES =
      "af,sq,ar,be,bn,bg,ca,zh,hr,cs,da,nl,en,eo,et,fi,fr,gl,ka,de,el,gu,ht,he,hi,hu,is,id,ga,it,ja,kn,ko,lv,lt,mk,ms,mt,mr,no,fa,pl,pt,ro,ru,sk,sl,es,sw,sv,tl,ta,te,th,tr,uk,ur,vi,cy";

  String? get translateSourceArgs {
    if (StringUtil.isNotBlank(_settingData!.translateSourceArgs)) {
      return _settingData!.translateSourceArgs!;
    }
  }

  String? get translateTarget => _settingData!.translateTarget;

  Map<String, int> _translateSourceArgsMap = {};

  void _reloadTranslateSourceArgs() {
    _translateSourceArgsMap.clear();
    var args = _settingData!.translateSourceArgs;
    if (StringUtil.isNotBlank(args)) {
      var argStrs = args!.split(",");
      for (var argStr in argStrs) {
        if (StringUtil.isNotBlank(argStr)) {
          _translateSourceArgsMap[argStr] = 1;
        }
      }
    }
  }

  bool translateSourceArgsCheck(String str) {
    return _translateSourceArgsMap[str] != null;
  }

  set settingData(SettingData o) {
    _settingData = o;
    saveAndNotifyListeners();
  }

  set privateKeyIndex(int? o) {
    _settingData!.privateKeyIndex = o;
    saveAndNotifyListeners();
  }

  // set privateKeyMap(String? o) {
  //   _settingData!.privateKeyMap = o;
  //   saveAndNotifyListeners();
  // }

  /// open lock
  set lockOpen(int o) {
    _settingData!.lockOpen = o;
    saveAndNotifyListeners();
  }

  set defaultIndex(int? o) {
    _settingData!.defaultIndex = o;
    saveAndNotifyListeners();
  }

  set defaultTab(int? o) {
    _settingData!.defaultTab = o;
    saveAndNotifyListeners();
  }

  set linkPreview(int o) {
    _settingData!.linkPreview = o;
    saveAndNotifyListeners();
  }

  set videoPreviewInList(int o) {
    _settingData!.videoPreviewInList = o;
    saveAndNotifyListeners();
  }

  set network(String? o) {
    _settingData!.network = o;
    saveAndNotifyListeners();
  }

  set imageService(String? o) {
    _settingData!.imageService = o;
    saveAndNotifyListeners();
  }

  set videoPreview(int? o) {
    _settingData!.videoPreview = o;
    saveAndNotifyListeners();
  }

  set imagePreview(int? o) {
    _settingData!.imagePreview = o;
    saveAndNotifyListeners();
  }

  /// i18n
  set i18n(String? o) {
    _settingData!.i18n = o;
    saveAndNotifyListeners();
  }

  void setI18n(String? i18n, String? i18nCC) {
    _settingData!.i18n = i18n;
    _settingData!.i18nCC = i18nCC;
    saveAndNotifyListeners();
  }

  /// image compress
  set imgCompress(int o) {
    _settingData!.imgCompress = o;
    saveAndNotifyListeners();
  }

  /// theme style
  set themeStyle(int o) {
    _settingData!.themeStyle = o;
    saveAndNotifyListeners();
  }

  /// theme color
  set themeColor(int? o) {
    _settingData!.themeColor = o;
    saveAndNotifyListeners();
  }

  /// fontFamily
  set fontFamily(String? _fontFamily) {
    _settingData!.fontFamily = _fontFamily;
    saveAndNotifyListeners();
  }

  set openTranslate(int? o) {
    _settingData!.openTranslate = o;
    saveAndNotifyListeners();
  }

  set translateSourceArgs(String? o) {
    _settingData!.translateSourceArgs = o;
    saveAndNotifyListeners();
  }

  set translateTarget(String? o) {
    _settingData!.translateTarget = o;
    saveAndNotifyListeners();
  }

  Future<void> saveAndNotifyListeners({bool updateUI = true}) async {
    _settingData!.updatedTime = DateTime.now().millisecondsSinceEpoch;
    var m = _settingData!.toJson();
    var jsonStr = json.encode(m);
    // print(jsonStr);
    await _sharedPreferences!.setString(DataKey.SETTING, jsonStr);
    _settingProvider!._reloadTranslateSourceArgs();

    if (updateUI) {
      notifyListeners();
    }
  }
}

class SettingData {
  int? privateKeyIndex;

  String? privateKeyMap;

  /// open lock
  late int lockOpen;

  int? defaultIndex;

  int? defaultTab;

  int? linkPreview;

  int? videoPreviewInList;

  String? network;

  String? imageService;

  int? videoPreview;

  int? imagePreview;

  /// i18n
  String? i18n;

  String? i18nCC;

  /// image compress
  late int imgCompress;

  /// theme style
  late int themeStyle;

  /// theme color
  int? themeColor;

  /// fontFamily
  String? fontFamily;

  int? openTranslate;

  String? translateTarget;

  String? translateSourceArgs;

  /// updated time
  late int updatedTime;

  SettingData({
    this.privateKeyIndex,
    this.privateKeyMap,
    this.lockOpen = OpenStatus.CLOSE,
    this.defaultIndex,
    this.defaultTab,
    this.linkPreview,
    this.videoPreviewInList,
    this.network,
    this.imageService,
    this.videoPreview,
    this.imagePreview,
    this.i18n,
    this.i18nCC,
    this.imgCompress = 50,
    this.themeStyle = ThemeStyle.AUTO,
    this.themeColor,
    this.fontFamily,
    this.openTranslate,
    this.translateTarget,
    this.translateSourceArgs,
    this.updatedTime = 0,
  });

  SettingData.fromJson(Map<String, dynamic> json) {
    privateKeyIndex = json['privateKeyIndex'];
    privateKeyMap = json['privateKeyMap'];
    if (json['lockOpen'] != null) {
      lockOpen = json['lockOpen'];
    } else {
      lockOpen = OpenStatus.CLOSE;
    }
    defaultIndex = json['defaultIndex'];
    defaultTab = json['defaultTab'];
    linkPreview = json['linkPreview'];
    videoPreviewInList = json['videoPreviewInList'];
    network = json['network'];
    imageService = json['imageService'];
    videoPreview = json['videoPreview'];
    imagePreview = json['imagePreview'];
    i18n = json['i18n'];
    i18nCC = json['i18nCC'];
    if (json['imgCompress'] != null) {
      imgCompress = json['imgCompress'];
    } else {
      imgCompress = 50;
    }
    if (json['themeStyle'] != null) {
      themeStyle = json['themeStyle'];
    } else {
      themeStyle = ThemeStyle.AUTO;
    }
    themeColor = json['themeColor'];
    openTranslate = json['openTranslate'];
    translateTarget = json['translateTarget'];
    translateSourceArgs = json['translateSourceArgs'];
    if (json['updatedTime'] != null) {
      updatedTime = json['updatedTime'];
    } else {
      updatedTime = 0;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['privateKeyIndex'] = this.privateKeyIndex;
    data['privateKeyMap'] = this.privateKeyMap;
    data['lockOpen'] = this.lockOpen;
    data['defaultIndex'] = this.defaultIndex;
    data['defaultTab'] = this.defaultTab;
    data['linkPreview'] = this.linkPreview;
    data['videoPreviewInList'] = this.videoPreviewInList;
    data['network'] = this.network;
    data['imageService'] = this.imageService;
    data['videoPreview'] = this.videoPreview;
    data['imagePreview'] = this.imagePreview;
    data['i18n'] = this.i18n;
    data['i18nCC'] = this.i18nCC;
    data['imgCompress'] = this.imgCompress;
    data['themeStyle'] = this.themeStyle;
    data['themeColor'] = this.themeColor;
    data['fontFamily'] = this.fontFamily;
    data['openTranslate'] = this.openTranslate;
    data['translateTarget'] = this.translateTarget;
    data['translateSourceArgs'] = this.translateSourceArgs;
    data['updatedTime'] = this.updatedTime;
    return data;
  }
}
