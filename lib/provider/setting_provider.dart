import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/util/encrypt_util.dart';
import 'package:nostrmo/util/table_mode_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../consts/base.dart';
import '../consts/base_consts.dart';
import '../consts/theme_style.dart';
import 'data_util.dart';

class SettingProvider extends ChangeNotifier {
  static SettingProvider? _settingProvider;

  SharedPreferences? _sharedPreferences;

  SettingData? _settingData;

  Map<String, String> _privateKeyMap = {};

  Map<String, String> _nwcUrlMap = {};

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
        _nwcUrlMap.clear();

        // move privateKeyMap to encryptPrivateKeyMap since 1.2.0
        String? privateKeyMapText = _settingData!.encryptPrivateKeyMap;
        try {
          if (StringUtil.isNotBlank(privateKeyMapText)) {
            privateKeyMapText = EncryptUtil.aesDecrypt(
                privateKeyMapText!, Base.KEY_EKEY, Base.KEY_IV);
          } else if (StringUtil.isNotBlank(_settingData!.privateKeyMap) &&
              StringUtil.isBlank(_settingData!.encryptPrivateKeyMap)) {
            privateKeyMapText = _settingData!.privateKeyMap;
            _settingData!.encryptPrivateKeyMap = EncryptUtil.aesEncrypt(
                _settingData!.privateKeyMap!, Base.KEY_EKEY, Base.KEY_IV);
            _settingData!.privateKeyMap = null;
          }
        } catch (e) {
          log("settingProvider handle privateKey error");
          log(e.toString());
        }

        if (StringUtil.isNotBlank(privateKeyMapText)) {
          try {
            var jsonKeyMap = jsonDecode(privateKeyMapText!);
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

        var nwcUrlMap = _settingData!.nwcUrlMap;
        if (StringUtil.isNotBlank(nwcUrlMap)) {
          try {
            nwcUrlMap =
                EncryptUtil.aesDecrypt(nwcUrlMap!, Base.KEY_EKEY, Base.KEY_IV);
            var jsonKeyMap = jsonDecode(nwcUrlMap);
            if (jsonKeyMap != null) {
              for (var entry in (jsonKeyMap as Map<String, dynamic>).entries) {
                _nwcUrlMap[entry.key] = entry.value;
              }
            }
          } catch (e) {
            log("_settingData!.nwcUrlMap! jsonDecode error");
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
        _settingData!.encryptPrivateKeyMap != null &&
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

        // _settingData!.privateKeyMap = json.encode(_privateKeyMap);
        _encodePrivateKeyMap();
        saveAndNotifyListeners(updateUI: updateUI);

        return i;
      }
    }

    return -1;
  }

  void _encodePrivateKeyMap() {
    var privateKeyMap = json.encode(_privateKeyMap);
    _settingData!.encryptPrivateKeyMap =
        EncryptUtil.aesEncrypt(privateKeyMap, Base.KEY_EKEY, Base.KEY_IV);
  }

  void removeKey(int index) {
    var indexStr = index.toString();

    _privateKeyMap.remove(indexStr);
    _encodePrivateKeyMap();

    _nwcUrlMap.remove(indexStr);
    _encodeNwcUrlMap();

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

  set nwcUrl(String? o) {
    var indexKey = _settingData!.privateKeyIndex.toString();
    if (StringUtil.isNotBlank(o)) {
      _nwcUrlMap[indexKey] = o!;
    } else {
      _nwcUrlMap.remove(indexKey);
    }

    _encodeNwcUrlMap();
    saveAndNotifyListeners();
  }

  String? get nwcUrl {
    var indexKey = _settingData!.privateKeyIndex.toString();
    return _nwcUrlMap[indexKey];
  }

  void _encodeNwcUrlMap() {
    var nwcUrlMap = json.encode(_nwcUrlMap);
    _settingData!.nwcUrlMap =
        EncryptUtil.aesEncrypt(nwcUrlMap, Base.KEY_EKEY, Base.KEY_IV);
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
      : OpenStatus.OPEN;

  String? get network => _settingData!.network;

  String? get imageService => _settingData!.imageService;

  String? get imageServiceAddr => _settingData!.imageServiceAddr;

  int? get videoPreview => _settingData!.videoPreview;
  // linux appimage don't support video preview.
  // int? get videoPrevisew => OpenStatus.CLOSE;

  int? get imagePreview => _settingData!.imagePreview;

  int? get profilePicturePreview => _settingData!.profilePicturePreview;

  /// i18n
  String? get i18n => _settingData!.i18n;

  String? get i18nCC => _settingData!.i18nCC;

  /// image compress
  int get imgCompress => _settingData!.imgCompress;

  /// theme style
  int get themeStyle => _settingData!.themeStyle;

  /// theme color
  int? get themeColor => _settingData!.themeColor;

  int? get mainFontColor => _settingData!.mainFontColor;

  int? get hintFontColor => _settingData!.hintFontColor;

  int? get cardColor => _settingData!.cardColor;

  String? get backgroundImage => _settingData!.backgroundImage;

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

  int? get broadcaseWhenBoost =>
      _settingData!.broadcaseWhenBoost ?? OpenStatus.OPEN;

  double get fontSize =>
      _settingData!.fontSize ??
      (TableModeUtil.isTableMode()
          ? Base.BASE_FONT_SIZE_PC
          : Base.BASE_FONT_SIZE);

  int get webviewAppbarOpen => _settingData!.webviewAppbarOpen;

  int? get tableMode => _settingData!.tableMode;

  int? get autoOpenSensitive => _settingData!.autoOpenSensitive;

  int? get relayLocal => _settingData!.relayLocal;

  int? get relayMode => _settingData!.relayMode;

  int? get eventSignCheck => _settingData!.eventSignCheck;

  int? get limitNoteHeight => _settingData!.limitNoteHeight;

  int? get threadMode => _settingData!.threadMode;

  int? get maxSubEventLevel => _settingData!.maxSubEventLevel;

  int? get hideRelayNotices => _settingData!.hideRelayNotices;

  int? get openBlurhashImage => _settingData!.openBlurhashImage;

  int? get pubkeyColor => _settingData!.pubkeyColor;

  int? get wotFilter => _settingData!.wotFilter;

  int? get mentionNoteNotice => _settingData!.wotFilter;

  int? get followNoteNotice => _settingData!.followNoteNotice;

  int? get messageNotice => _settingData!.messageNotice;

  String? get noteClientTag => _settingData!.noteClientTag;

  String? get noteTail => _settingData!.noteTail;

  int? get pow => _settingData!.pow;

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

  set imageServiceAddr(String? o) {
    _settingData!.imageServiceAddr = o;
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

  set profilePicturePreview(int? o) {
    _settingData!.profilePicturePreview = o;
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

  set mainFontColor(int? o) {
    _settingData!.mainFontColor = o;
    saveAndNotifyListeners();
  }

  set hintFontColor(int? o) {
    _settingData!.hintFontColor = o;
    saveAndNotifyListeners();
  }

  set cardColor(int? o) {
    _settingData!.cardColor = o;
    saveAndNotifyListeners();
  }

  set backgroundImage(String? o) {
    _settingData!.backgroundImage = o;
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

  set broadcaseWhenBoost(int? o) {
    _settingData!.broadcaseWhenBoost = o;
    saveAndNotifyListeners();
  }

  set fontSize(double o) {
    _settingData!.fontSize = o;
    saveAndNotifyListeners();
  }

  set webviewAppbarOpen(int o) {
    _settingData!.webviewAppbarOpen = o;
    saveAndNotifyListeners();
  }

  set tableMode(int? o) {
    _settingData!.tableMode = o;
    saveAndNotifyListeners();
  }

  set autoOpenSensitive(int? o) {
    _settingData!.autoOpenSensitive = o;
    saveAndNotifyListeners();
  }

  set relayLocal(int? o) {
    _settingData!.relayLocal = o;
    saveAndNotifyListeners();
  }

  set relayMode(int? o) {
    _settingData!.relayMode = o;
    saveAndNotifyListeners();
  }

  set eventSignCheck(int? o) {
    _settingData!.eventSignCheck = o;
    saveAndNotifyListeners();
  }

  set limitNoteHeight(int? o) {
    _settingData!.limitNoteHeight = o;
    saveAndNotifyListeners();
  }

  set threadMode(int? o) {
    _settingData!.threadMode = o;
    saveAndNotifyListeners();
  }

  set maxSubEventLevel(int? o) {
    _settingData!.maxSubEventLevel = o;
    saveAndNotifyListeners();
  }

  set hideRelayNotices(int? o) {
    _settingData!.hideRelayNotices = o;
    saveAndNotifyListeners();
  }

  set openBlurhashImage(int? o) {
    _settingData!.openBlurhashImage = o;
    saveAndNotifyListeners();
  }

  set pubkeyColor(int? o) {
    _settingData!.pubkeyColor = o;
    saveAndNotifyListeners();
  }

  set wotFilter(int? o) {
    _settingData!.wotFilter = o;
    saveAndNotifyListeners();
  }

  set mentionNoteNotice(int? o) {
    _settingData!.mentionNoteNotice = o;
    saveAndNotifyListeners();
  }

  set followNoteNotice(int? o) {
    _settingData!.followNoteNotice = o;
    saveAndNotifyListeners();
  }

  set messageNotice(int? o) {
    _settingData!.messageNotice = o;
    saveAndNotifyListeners();
  }

  set noteClientTag(String? o) {
    _settingData!.noteClientTag = o;
    saveAndNotifyListeners();
  }

  set noteTail(String? o) {
    _settingData!.noteTail = o;
    saveAndNotifyListeners();
  }

  set pow(int? o) {
    _settingData!.pow = o;
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

  String? encryptPrivateKeyMap;

  /// open lock
  late int lockOpen;

  int? defaultIndex;

  int? defaultTab;

  int? linkPreview;

  int? videoPreviewInList;

  String? network;

  String? imageService;

  String? imageServiceAddr;

  int? videoPreview;

  int? imagePreview;

  int? profilePicturePreview;

  /// i18n
  String? i18n;

  String? i18nCC;

  /// image compress
  late int imgCompress;

  /// theme style
  late int themeStyle;

  /// theme color
  int? themeColor;

  /// main font color
  int? mainFontColor;

  /// hint font color
  int? hintFontColor;

  /// card color
  int? cardColor;

  String? backgroundImage;

  /// fontFamily
  String? fontFamily;

  int? openTranslate;

  String? translateTarget;

  String? translateSourceArgs;

  int? broadcaseWhenBoost;

  double? fontSize;

  late int webviewAppbarOpen;

  int? tableMode;

  int? autoOpenSensitive;

  int? relayLocal;

  int? relayMode;

  int? eventSignCheck;

  int? limitNoteHeight;

  int? threadMode;

  int? maxSubEventLevel;

  int? hideRelayNotices;

  String? nwcUrlMap;

  int? openBlurhashImage;

  int? pubkeyColor;

  int? wotFilter;

  int? mentionNoteNotice;

  int? followNoteNotice;

  int? messageNotice;

  String? noteClientTag;

  String? noteTail;

  int? pow;

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
    this.imageServiceAddr,
    this.videoPreview,
    this.imagePreview,
    this.profilePicturePreview,
    this.i18n,
    this.i18nCC,
    this.imgCompress = 50,
    this.themeStyle = ThemeStyle.AUTO,
    this.themeColor,
    this.mainFontColor,
    this.hintFontColor,
    this.cardColor,
    this.backgroundImage,
    this.fontFamily,
    this.openTranslate,
    this.translateTarget,
    this.translateSourceArgs,
    this.broadcaseWhenBoost,
    this.fontSize,
    this.webviewAppbarOpen = OpenStatus.OPEN,
    this.tableMode,
    this.autoOpenSensitive,
    this.relayLocal,
    this.relayMode,
    this.eventSignCheck,
    this.limitNoteHeight,
    this.threadMode,
    this.maxSubEventLevel,
    this.hideRelayNotices,
    this.nwcUrlMap,
    this.openBlurhashImage,
    this.pubkeyColor,
    this.wotFilter,
    this.mentionNoteNotice,
    this.followNoteNotice,
    this.messageNotice,
    this.noteClientTag,
    this.noteTail,
    this.pow,
    this.updatedTime = 0,
  });

  SettingData.fromJson(Map<String, dynamic> json) {
    privateKeyIndex = json['privateKeyIndex'];
    privateKeyMap = json['privateKeyMap'];
    encryptPrivateKeyMap = json['encryptPrivateKeyMap'];
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
    imageServiceAddr = json['imageServiceAddr'];
    videoPreview = json['videoPreview'];
    imagePreview = json['imagePreview'];
    profilePicturePreview = json['profilePicturePreview'];
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
    mainFontColor = json['mainFontColor'];
    hintFontColor = json['hintFontColor'];
    cardColor = json['cardColor'];
    backgroundImage = json['backgroundImage'];
    fontFamily = json['fontFamily'];
    openTranslate = json['openTranslate'];
    translateTarget = json['translateTarget'];
    translateSourceArgs = json['translateSourceArgs'];
    broadcaseWhenBoost = json['broadcaseWhenBoost'];
    fontSize = json['fontSize'];
    webviewAppbarOpen = json['webviewAppbarOpen'] != null
        ? json['webviewAppbarOpen']
        : OpenStatus.OPEN;
    tableMode = json['tableMode'];
    autoOpenSensitive = json['autoOpenSensitive'];
    relayLocal = json['relayLocal'];
    relayMode = json['relayMode'];
    eventSignCheck = json['eventSignCheck'];
    limitNoteHeight = json['limitNoteHeight'];
    threadMode = json['threadMode'];
    maxSubEventLevel = json['maxSubEventLevel'];
    hideRelayNotices = json['hideRelayNotices'];
    nwcUrlMap = json['nwcUrlMap'];
    openBlurhashImage = json['openBlurhashImage'];
    pubkeyColor = json['pubkeyColor'];
    wotFilter = json['wotFilter'];
    mentionNoteNotice = json['mentionNoteNotice'];
    followNoteNotice = json['followNoteNotice'];
    messageNotice = json['messageNotice'];
    noteClientTag = json['noteClientTag'];
    noteTail = json['noteTail'];
    pow = json['pow'];
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
    data['encryptPrivateKeyMap'] = this.encryptPrivateKeyMap;
    data['lockOpen'] = this.lockOpen;
    data['defaultIndex'] = this.defaultIndex;
    data['defaultTab'] = this.defaultTab;
    data['linkPreview'] = this.linkPreview;
    data['videoPreviewInList'] = this.videoPreviewInList;
    data['network'] = this.network;
    data['imageService'] = this.imageService;
    data['imageServiceAddr'] = this.imageServiceAddr;
    data['videoPreview'] = this.videoPreview;
    data['imagePreview'] = this.imagePreview;
    data['profilePicturePreview'] = this.profilePicturePreview;
    data['i18n'] = this.i18n;
    data['i18nCC'] = this.i18nCC;
    data['imgCompress'] = this.imgCompress;
    data['themeStyle'] = this.themeStyle;
    data['themeColor'] = this.themeColor;
    data['mainFontColor'] = this.mainFontColor;
    data['hintFontColor'] = this.hintFontColor;
    data['cardColor'] = this.cardColor;
    data['backgroundImage'] = this.backgroundImage;
    data['fontFamily'] = this.fontFamily;
    data['openTranslate'] = this.openTranslate;
    data['translateTarget'] = this.translateTarget;
    data['translateSourceArgs'] = this.translateSourceArgs;
    data['broadcaseWhenBoost'] = this.broadcaseWhenBoost;
    data['fontSize'] = this.fontSize;
    data['webviewAppbarOpen'] = this.webviewAppbarOpen;
    data['tableMode'] = this.tableMode;
    data['autoOpenSensitive'] = this.autoOpenSensitive;
    data['relayLocal'] = this.relayLocal;
    data['relayMode'] = this.relayMode;
    data['eventSignCheck'] = this.eventSignCheck;
    data['limitNoteHeight'] = this.limitNoteHeight;
    data['threadMode'] = this.threadMode;
    data['maxSubEventLevel'] = this.maxSubEventLevel;
    data['hideRelayNotices'] = this.hideRelayNotices;
    data['nwcUrlMap'] = this.nwcUrlMap;
    data['openBlurhashImage'] = this.openBlurhashImage;
    data['pubkeyColor'] = this.pubkeyColor;
    data['wotFilter'] = this.wotFilter;
    data['mentionNoteNotice'] = this.mentionNoteNotice;
    data['followNoteNotice'] = this.followNoteNotice;
    data['wotFilter'] = this.wotFilter;
    data['messageNotice'] = this.messageNotice;
    data['noteClientTag'] = this.noteClientTag;
    data['noteTail'] = this.noteTail;
    data['pow'] = this.pow;
    return data;
  }
}
