import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostrmo/consts/lock_open.dart';
import 'package:nostrmo/consts/theme_style.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    notifyListeners();
  }

  String? get privateKey {
    if (_settingData!.privateKeyIndex != null &&
        _settingData!.privateKeyMap != null &&
        _privateKeyMap.isNotEmpty) {
      return _privateKeyMap[_settingData!.privateKeyIndex.toString()];
    }
    return null;
  }

  int addAndChangePrivateKey(String pk, {bool updateUI = false}) {
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

  /// i18n
  String? get i18n => _settingData!.i18n;

  /// image compress
  int get imgCompress => _settingData!.imgCompress;

  /// theme style
  int get themeStyle => _settingData!.themeStyle;

  /// theme color
  int? get themeColor => _settingData!.themeColor;

  set settingData(SettingData o) {
    _settingData = o;
    saveAndNotifyListeners();
  }

  // set privateKeyIndex(int? o) {
  //   _settingData!.privateKeyIndex = o;
  //   saveAndNotifyListeners();
  // }

  // set privateKeyMap(String? o) {
  //   _settingData!.privateKeyMap = o;
  //   saveAndNotifyListeners();
  // }

  /// open lock
  set lockOpen(int o) {
    _settingData!.lockOpen = o;
    saveAndNotifyListeners();
  }

  /// i18n
  set i18n(String? o) {
    _settingData!.i18n = o;
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

  Future<void> saveAndNotifyListeners({bool updateUI = true}) async {
    _settingData!.updatedTime = DateTime.now().millisecondsSinceEpoch;
    var m = _settingData!.toJson();
    var jsonStr = json.encode(m);
    // print(jsonStr);
    await _sharedPreferences!.setString(DataKey.SETTING, jsonStr);

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

  /// i18n
  String? i18n;

  /// image compress
  late int imgCompress;

  /// theme style
  late int themeStyle;

  /// theme color
  int? themeColor;

  /// updated time
  late int updatedTime;

  SettingData({
    this.privateKeyIndex,
    this.privateKeyMap,
    this.lockOpen = LockOpen.CLOSE,
    this.i18n,
    this.imgCompress = 50,
    this.themeStyle = ThemeStyle.AUTO,
    this.themeColor,
    this.updatedTime = 0,
  });

  SettingData.fromJson(Map<String, dynamic> json) {
    privateKeyIndex = json['privateKeyIndex'];
    privateKeyMap = json['privateKeyMap'];
    if (json['lockOpen'] != null) {
      lockOpen = json['lockOpen'];
    } else {
      lockOpen = LockOpen.CLOSE;
    }
    i18n = json['i18n'];
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
    data['i18n'] = this.i18n;
    data['imgCompress'] = this.imgCompress;
    data['themeStyle'] = this.themeStyle;
    data['themeColor'] = this.themeColor;
    data['updatedTime'] = this.updatedTime;
    return data;
  }
}
