import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_picker/flutter_font_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nostrmo/component/editor/text_input_dialog.dart';
import 'package:nostrmo/consts/image_services.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:provider/provider.dart';

import '../../component/colors_selector_component.dart';
import '../../component/enum_selector_component.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../consts/lock_open copy.dart';
import '../../consts/theme_style copy.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/auth_util.dart';
import '../../util/locale_util.dart';
import '../../util/string_util.dart';
import 'setting_group_item_component.dart';
import 'setting_group_title_component.dart';

class SettingRouter extends StatefulWidget {
  Function indexReload;

  SettingRouter({
    required this.indexReload,
  });

  @override
  State<StatefulWidget> createState() {
    return _SettingRouter();
  }
}

class _SettingRouter extends State<SettingRouter> {
  void resetTheme() {
    widget.indexReload();
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var _settingProvider = Provider.of<SettingProvider>(context);

    var mainColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;

    var s = S.of(context);

    initOpenList(s);
    initI18nList(s);
    initCompressList(s);
    initLockOpenList(s);
    initDefaultList(s);
    initDefaultTabListTimeline(s);
    initDefaultTabListGlobal(s);

    initThemeStyleList(s);
    initFontEnumList(s);
    initImageServcieList();

    List<Widget> list = [];

    list.add(
      SettingGroupItemComponent(
        name: s.Language,
        value: getI18nList(_settingProvider.i18n, _settingProvider.i18nCC).name,
        onTap: pickI18N,
      ),
    );
    list.add(SettingGroupItemComponent(
      name: s.Image_Compress,
      value: getCompressList(settingProvider.imgCompress).name,
      onTap: pickImageCompressList,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Privacy_Lock,
      value: getLockOpenList(settingProvider.lockOpen).name,
      onTap: pickLockOpenList,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Default_index,
      value: getDefaultIndex(settingProvider.defaultIndex).name,
      onTap: pickDefaultIndex,
    ));
    List<EnumObj> defaultTabList = defaultTabListTimeline!;
    if (settingProvider.defaultIndex == 1) {
      defaultTabList = defaultTabListGlobal!;
    }
    list.add(SettingGroupItemComponent(
      name: s.Default_tab,
      value: getDefaultTab(defaultTabList, settingProvider.defaultTab).name,
      onTap: () {
        pickDefaultTab(defaultTabList);
      },
    ));

    list.add(SettingGroupTitleComponent(iconData: Icons.palette, title: "UI"));
    list.add(
      SettingGroupItemComponent(
        name: s.Theme_Style,
        value: getThemeStyle(_settingProvider.themeStyle).name,
        onTap: pickThemeStyle,
      ),
    );
    list.add(SettingGroupItemComponent(
      name: s.Theme_Color,
      onTap: pickColor,
      child: Container(
        height: 28,
        width: 28,
        color: mainColor,
      ),
    ));
    list.add(SettingGroupItemComponent(
      name: s.Font_Family,
      value: getFontEnumResult(settingProvider.fontFamily),
      onTap: pickFontEnum,
    ));

    list.add(
        SettingGroupTitleComponent(iconData: Icons.article, title: s.Notes));
    list.add(SettingGroupItemComponent(
      name: s.Link_preview,
      value: getOpenList(settingProvider.linkPreview).name,
      onTap: pickLinkPreview,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Video_preview_in_list,
      value: getOpenList(settingProvider.videoPreviewInList).name,
      onTap: pickVideoPreviewInList,
    ));
    String? networkHintText = settingProvider.network;
    if (StringUtil.isBlank(networkHintText)) {
      networkHintText = s.Please_input + " " + s.Network;
    }
    Widget networkWidget = Text(
      networkHintText!,
      style: TextStyle(
        color: hintColor,
        overflow: TextOverflow.ellipsis,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
    list.add(SettingGroupItemComponent(
      name: s.Network,
      onTap: inputNetwork,
      child: networkWidget,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Image_service,
      value: getImageServcie(settingProvider.imageService).name,
      onTap: pickImageServcie,
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.Setting,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
      ),
      body: Container(
        margin: EdgeInsets.only(top: Base.BASE_PADDING),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
        ),
        child: CustomScrollView(
          slivers: list,
        ),
      ),
    );
  }

  List<EnumObj>? openList;

  void initOpenList(S s) {
    if (openList == null) {
      openList = [];
      openList!.add(EnumObj(OpenStatus.OPEN, s.open));
      openList!.add(EnumObj(OpenStatus.CLOSE, s.close));
    }
  }

  EnumObj getOpenList(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    return openList![0];
  }

  List<EnumObj>? i18nList;

  void initI18nList(S s) {
    if (i18nList == null) {
      i18nList = [];
      i18nList!.add(EnumObj("", s.auto));
      for (var item in S.delegate.supportedLocales) {
        var key = LocaleUtil.getLocaleKey(item);
        i18nList!.add(EnumObj(key, key));
      }
    }
  }

  EnumObj getI18nList(String? i18n, String? i18nCC) {
    var key = LocaleUtil.genLocaleKeyFromSring(i18n, i18nCC);
    for (var eo in i18nList!) {
      if (eo.value == key) {
        return eo;
      }
    }
    return EnumObj("", S.of(context).auto);
  }

  Future pickI18N() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, i18nList!);
    if (resultEnumObj != null) {
      if (resultEnumObj.value == "") {
        settingProvider.setI18n(null, null);
      } else {
        for (var item in S.delegate.supportedLocales) {
          var key = LocaleUtil.getLocaleKey(item);
          if (resultEnumObj.value == key) {
            settingProvider.setI18n(item.languageCode, item.countryCode);
          }
        }
      }
      resetTheme();
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          // TODO others setting enumObjList
          i18nList = null;
          themeStyleList = null;
        });
      });
    }
  }

  List<EnumObj>? compressList;

  void initCompressList(S s) {
    if (compressList == null) {
      compressList = [];
      compressList!.add(EnumObj(100, s.Dont_Compress));
      compressList!.add(EnumObj(90, "90%"));
      compressList!.add(EnumObj(80, "80%"));
      compressList!.add(EnumObj(70, "70%"));
      compressList!.add(EnumObj(60, "60%"));
      compressList!.add(EnumObj(50, "50%"));
      compressList!.add(EnumObj(40, "40%"));
    }
  }

  Future<void> pickImageCompressList() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, compressList!);
    if (resultEnumObj != null) {
      settingProvider.imgCompress = resultEnumObj.value;
    }
  }

  EnumObj getCompressList(int compress) {
    for (var eo in compressList!) {
      if (eo.value == compress) {
        return eo;
      }
    }
    return compressList![0];
  }

  List<EnumObj>? lockOpenList;

  void initLockOpenList(S s) {
    if (lockOpenList == null) {
      lockOpenList = [];
      lockOpenList!.add(EnumObj(LockOpen.CLOSE, s.close));
      lockOpenList!.add(EnumObj(LockOpen.PIN_CODE, s.Password));
      lockOpenList!.add(EnumObj(LockOpen.FACE, s.Face));
      lockOpenList!.add(EnumObj(LockOpen.FINGERPRINT, s.Fingerprint));
    }
  }

  EnumObj getLockOpenList(int lockOpen) {
    for (var eo in lockOpenList!) {
      if (eo.value == lockOpen) {
        return eo;
      }
    }
    return lockOpenList![0];
  }

  Future<void> pickLockOpenList() async {
    List<EnumObj> newLockOpenList = [];
    newLockOpenList.add(lockOpenList![0]);
    // newLockOpenList.add(lockOpenList[1]); // 临时关闭 PinCode

    var localAuth = LocalAuthentication();
    List<BiometricType> availableBiometrics =
        await localAuth.getAvailableBiometrics();
    for (var bt in availableBiometrics) {
      if (bt == BiometricType.strong) {
        if (Platform.isIOS) {
          newLockOpenList.add(lockOpenList![2]);
        } else {
          newLockOpenList.add(lockOpenList![3]);
        }
      }
      print(bt);
    }

    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, newLockOpenList);
    if (resultEnumObj != null) {
      if (resultEnumObj.value == LockOpen.CLOSE) {
        if (settingProvider.lockOpen == LockOpen.FACE ||
            settingProvider.lockOpen == LockOpen.FINGERPRINT) {
          bool didAuthenticate = await AuthUtil.authenticate(context,
              S.of(context).Please_authenticate_to_turn_off_the_privacy_lock);
          if (didAuthenticate) {
            settingProvider.lockOpen = resultEnumObj.value;
          }
        }
        settingProvider.lockOpen = resultEnumObj.value;
      } else if (resultEnumObj.value == LockOpen.PIN_CODE) {
        settingProvider.lockOpen = resultEnumObj.value;
      } else if (resultEnumObj.value == LockOpen.FACE ||
          resultEnumObj.value == LockOpen.FINGERPRINT) {
        bool didAuthenticate = await AuthUtil.authenticate(context,
            S.of(context).Please_authenticate_to_turn_on_the_privacy_lock);
        if (didAuthenticate) {
          settingProvider.lockOpen = resultEnumObj.value;
        }
      }
    }
  }

  List<EnumObj>? defaultIndexList;

  void initDefaultList(S s) {
    if (defaultIndexList == null) {
      defaultIndexList = [];
      defaultIndexList!.add(EnumObj(0, s.Timeline));
      defaultIndexList!.add(EnumObj(1, s.Global));
    }
  }

  Future<void> pickDefaultIndex() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, defaultIndexList!);
    if (resultEnumObj != null) {
      settingProvider.defaultIndex = resultEnumObj.value;
      resetTheme();
    }
  }

  EnumObj getDefaultIndex(int? value) {
    for (var eo in defaultIndexList!) {
      if (eo.value == value) {
        return eo;
      }
    }
    return defaultIndexList![0];
  }

  List<EnumObj>? defaultTabListTimeline;

  void initDefaultTabListTimeline(S s) {
    if (defaultTabListTimeline == null) {
      defaultTabListTimeline = [];
      defaultTabListTimeline!.add(EnumObj(0, s.Posts));
      defaultTabListTimeline!.add(EnumObj(1, s.Posts_and_replies));
      defaultTabListTimeline!.add(EnumObj(2, s.Mentions));
    }
  }

  List<EnumObj>? defaultTabListGlobal;

  void initDefaultTabListGlobal(S s) {
    if (defaultTabListGlobal == null) {
      defaultTabListGlobal = [];
      defaultTabListGlobal!.add(EnumObj(0, s.Notes));
      defaultTabListGlobal!.add(EnumObj(1, s.Users));
      defaultTabListGlobal!.add(EnumObj(2, s.Topics));
    }
  }

  Future<void> pickDefaultTab(List<EnumObj> list) async {
    EnumObj? resultEnumObj = await EnumSelectorComponent.show(context, list);
    if (resultEnumObj != null) {
      settingProvider.defaultTab = resultEnumObj.value;
      resetTheme();
    }
  }

  EnumObj getDefaultTab(List<EnumObj> list, int? value) {
    for (var eo in list) {
      if (eo.value == value) {
        return eo;
      }
    }
    return list[0];
  }

  List<EnumObj>? themeStyleList;

  void initThemeStyleList(S s) {
    if (themeStyleList == null) {
      themeStyleList = [];
      themeStyleList?.add(EnumObj(ThemeStyle.AUTO, s.Follow_System));
      themeStyleList?.add(EnumObj(ThemeStyle.LIGHT, s.Light));
      themeStyleList?.add(EnumObj(ThemeStyle.DARK, s.Dark));
    }
  }

  Future<void> pickThemeStyle() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, themeStyleList!);
    if (resultEnumObj != null) {
      settingProvider.themeStyle = resultEnumObj.value;
      resetTheme();
    }
  }

  EnumObj getThemeStyle(int themeStyle) {
    for (var eo in themeStyleList!) {
      if (eo.value == themeStyle) {
        return eo;
      }
    }
    return themeStyleList![0];
  }

  Future<void> pickColor() async {
    Color? color = await ColorSelectorComponent.show(context);
    if (color != null) {
      settingProvider.themeColor = color.value;
      resetTheme();
    }
  }

  List<EnumObj>? fontEnumList;

  void initFontEnumList(S s) {
    if (fontEnumList == null) {
      fontEnumList = [];
      fontEnumList!.add(EnumObj(false, s.Default_Font_Family));
      fontEnumList!.add(EnumObj(true, s.Custom_Font_Family));
    }
  }

  String getFontEnumResult(String? fontFamily) {
    if (StringUtil.isNotBlank(fontFamily)) {
      return fontFamily!;
    }
    return fontEnumList![0].name;
  }

  Future pickFontEnum() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, fontEnumList!);
    if (resultEnumObj != null) {
      if (resultEnumObj.value == true) {
        pickFont();
      } else {
        settingProvider.fontFamily = null;
        resetTheme();
      }
    }
  }

  void pickFont() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FontPicker(
          onFontChanged: (PickerFont font) {
            // _selectedFont = font;
            print(
                "${font.fontFamily} with font weight ${font.fontWeight} and font style ${font.fontStyle}.}");
            settingProvider.fontFamily = font.fontFamily;
            resetTheme();
          },
        ),
      ),
    );
  }

  Future<void> pickLinkPreview() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.linkPreview = resultEnumObj.value;
    }
  }

  Future<void> pickVideoPreviewInList() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.videoPreviewInList = resultEnumObj.value;
    }
  }

  inputNetwork() async {
    var s = S.of(context);
    var text = await TextInputDialog.show(
      context,
      "${s.Please_input} ${s.Network}\nSOCKS5/SOCKS4/PROXY username:password@host:port",
      value: settingProvider.network,
    );
    settingProvider.network = text;
    BotToast.showText(text: s.network_take_effect_tip);
  }

  List<EnumObj>? imageServcieList;

  void initImageServcieList() {
    if (imageServcieList == null) {
      imageServcieList = [];
      imageServcieList!
          .add(EnumObj(ImageServices.NOSTR_BUILD, ImageServices.NOSTR_BUILD));
      imageServcieList!
          .add(EnumObj(ImageServices.NOSTRIMG_COM, ImageServices.NOSTRIMG_COM));
      imageServcieList!.add(
          EnumObj(ImageServices.POMF2_LAIN_LA, ImageServices.POMF2_LAIN_LA));
      // imageServcieList!
      //     .add(EnumObj(ImageServices.VOID_CAT, ImageServices.VOID_CAT));
    }
  }

  EnumObj getImageServcie(String? o) {
    for (var eo in imageServcieList!) {
      if (eo.value == o) {
        return eo;
      }
    }
    return imageServcieList![0];
  }

  Future<void> pickImageServcie() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, imageServcieList!);
    if (resultEnumObj != null) {
      settingProvider.imageService = resultEnumObj.value;
    }
  }
}
