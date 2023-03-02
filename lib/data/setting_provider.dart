import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nostrmo/consts/lock_open.dart';
import 'package:nostrmo/consts/theme_style.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'data_util.dart';

class SettingProvider extends ChangeNotifier {
  static SettingProvider? _settingProvider;

  SharedPreferences? _sharedPreferences;

  SettingData? _settingData;

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
        return;
      }
    }

    _settingData = SettingData();
  }

  Future<void> reload() async {
    await _init();
    notifyListeners();
  }

  SettingData get settingData => _settingData!;

  /// 是否开启隐私锁
  int get lockOpen => _settingData!.lockOpen;

  /// 国际化
  String? get i18n => _settingData!.i18n;

  /// 图片压缩
  int get imgCompress => _settingData!.imgCompress;

  /// 主题类型
  int get themeStyle => _settingData!.themeStyle;

  /// 主题颜色
  int? get themeColor => _settingData!.themeColor;

  set settingData(SettingData o) {
    _settingData = o;
    saveAndNotifyListeners(needUpdateTime: false);
  }

  /// 是否开启隐私锁
  set lockOpen(int o) {
    _settingData!.lockOpen = o;
    saveAndNotifyListeners();
  }

  /// 国际化
  set i18n(String? o) {
    _settingData!.i18n = o;
    saveAndNotifyListeners();
  }

  /// 图片压缩
  set imgCompress(int o) {
    _settingData!.imgCompress = o;
    saveAndNotifyListeners();
  }

  /// 主题类型
  set themeStyle(int o) {
    _settingData!.themeStyle = o;
    saveAndNotifyListeners();
  }

  /// 主题颜色
  set themeColor(int? o) {
    _settingData!.themeColor = o;
    saveAndNotifyListeners();
  }

  Future<void> saveAndNotifyListeners({bool needUpdateTime = true}) async {
    if (needUpdateTime) {
      // 是否需要更新数据，因为从远程更新到本地时不更新数据的话，可以减少同步的次数
      _settingData!.updatedTime = DateTime.now().millisecondsSinceEpoch;
    }
    var m = _settingData!.toJson();
    var jsonStr = json.encode(m);
    // print(jsonStr);
    await _sharedPreferences!.setString(DataKey.SETTING, jsonStr);
    notifyListeners();
    // CloudSyncer.getInstance().syncSetting();
  }
}

class SettingData {
  /// 是否开启隐私锁
  late int lockOpen;

  /// 国际化
  String? i18n;

  /// 图片压缩
  late int imgCompress;

  /// 主题类型
  late int themeStyle;

  /// 主题颜色
  int? themeColor;

  /// 更新时间
  late int updatedTime;

  SettingData({
    this.lockOpen = LockOpen.CLOSE,
    this.i18n,
    this.imgCompress = 50,
    this.themeStyle = ThemeStyle.AUTO,
    this.themeColor,
    this.updatedTime = 0,
  });

  SettingData.fromJson(Map<String, dynamic> json) {
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
    data['lockOpen'] = this.lockOpen;
    data['i18n'] = this.i18n;
    data['imgCompress'] = this.imgCompress;
    data['themeStyle'] = this.themeStyle;
    data['themeColor'] = this.themeColor;
    data['updatedTime'] = this.updatedTime;
    return data;
  }
}
