import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_font_picker/flutter_font_picker.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip02/contact_list.dart';
import 'package:nostr_sdk/relay/relay_mode.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostrmo/component/color_pick_dialog.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/consts/thread_mode.dart';
import 'package:nostrmo/router/index/account_manager_component.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/store_util.dart';
import 'package:nostr_sdk/utils/when_stop_function.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/cache_remove_dialog.dart';
import '../../component/colors_selector_component.dart';
import '../../component/confirm_dialog.dart';
import '../../component/editor/text_input_dialog.dart';
import '../../component/enum_multi_selector_component.dart';
import '../../component/enum_selector_component.dart';
import '../../component/translate/translate_model_manager.dart';
import '../../consts/base_consts.dart';
import '../../consts/image_services.dart';
import '../../consts/theme_style.dart';
import '../../data/metadata.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/filter_provider.dart';
import '../../provider/setting_provider.dart';
import '../../provider/uploader.dart';
import '../../util/auth_util.dart';
import '../../util/locale_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
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

class _SettingRouter extends State<SettingRouter> with WhenStopFunction {
  void resetTheme() {
    widget.indexReload();
  }

  late S s;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var _settingProvider = Provider.of<SettingProvider>(context);
    var valueFontSize = themeData.textTheme.bodyMedium!.fontSize;
    var filterProvider = Provider.of<FilterProvider>(context);

    var mainColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;
    var cardColor = themeData.cardColor;

    s = S.of(context);

    initOpenList(s);
    initI18nList(s);
    initCompressList(s);
    initDefaultList(s);
    initDefaultTabListTimeline(s);
    initDefaultTabListGlobal(s);
    initColorStyleEnumList(s);

    initThemeStyleList(s);
    initFontEnumList(s);
    initImageServcieList();
    initTranslateLanguages();
    initThreadModes();

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
    if (!PlatformUtil.isPC()) {
      list.add(SettingGroupItemComponent(
        name: s.Privacy_Lock,
        value: getLockOpenList(settingProvider.lockOpen).name,
        onTap: pickLockOpenList,
      ));
    }
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

    String nwcValue = getOpenList(OpenStatus.OPEN).name;
    if (StringUtil.isBlank(settingProvider.nwcUrl)) {
      nwcValue = getOpenList(OpenStatus.CLOSE).name;
    }
    list.add(SettingGroupItemComponent(
      name: "NWC ${s.Setting}",
      value: nwcValue,
      onTap: () {
        RouterUtil.router(context, RouterPath.NWC_SETTING);
      },
    ));

    list.add(SettingGroupItemComponent(
      name: "Wot ${s.Filter}",
      value: getOpenListDefault(settingProvider.wotFilter).name,
      onTap: pickWotFilter,
    ));

    list.add(SettingGroupItemComponent(
      name: s.Tags_Spam_Filter,
      value: getOpenListDefault(filterProvider.tagsSpamNum > 0
              ? OpenStatus.OPEN
              : OpenStatus.CLOSE)
          .name,
      onTap: pickTagsSpamFilter,
      onLongPress: pickTagsSpamFilterNumber,
    ));

    if (PlatformUtil.isPC()) {
      list.add(SettingGroupItemComponent(
        name: s.Mentioned_note_notice,
        value: getOpenList(settingProvider.mentionNoteNotice).name,
        onTap: pickMentionNoteNotice,
      ));

      list.add(SettingGroupItemComponent(
        name: s.Follow_note_notice,
        value: getOpenList(settingProvider.followNoteNotice).name,
        onTap: pickFollowNoteNotice,
      ));

      list.add(SettingGroupItemComponent(
        name: s.Message_notice,
        value: getOpenList(settingProvider.messageNotice).name,
        onTap: pickMessageNotice,
      ));
    }

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
    var textStyle = TextStyle(
      color: hintColor,
      fontWeight: FontWeight.bold,
      fontSize: valueFontSize,
    );
    list.add(SettingGroupItemComponent(
      name: s.Card_Color,
      onTap: pickCardColor,
      child: getCustomColorWidget(settingProvider.cardColor, textStyle),
    ));
    list.add(SettingGroupItemComponent(
      name: s.Main_Font_Color,
      onTap: pickMainFontColor,
      child: getCustomColorWidget(settingProvider.mainFontColor, textStyle),
    ));
    list.add(SettingGroupItemComponent(
      name: s.Hint_Font_Color,
      onTap: pickHintFontColor,
      child: getCustomColorWidget(settingProvider.hintFontColor, textStyle),
    ));
    list.add(SettingGroupItemComponent(
      name: s.Background_Image,
      onTap: pickBackgroundImage,
      child: Container(),
    ));
    list.add(SettingGroupItemComponent(
      name: s.Font_Family,
      value: getFontEnumResult(settingProvider.fontFamily),
      onTap: pickFontEnum,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Font_Size,
      value: getFontSize(settingProvider.fontSize).name,
      onTap: pickFontSize,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Web_Appbar,
      value: getOpenList(settingProvider.webviewAppbarOpen).name,
      onTap: pickWebviewAppbar,
    ));
    if (!PlatformUtil.isPC()) {
      list.add(SettingGroupItemComponent(
        name: s.Table_Mode,
        value: getOpenMode(settingProvider.tableMode).name,
        onTap: pickOpenMode,
      ));
    }
    list.add(SettingGroupItemComponent(
      name: "${s.Pubkey} ${s.Color}",
      value: getOpenList(settingProvider.pubkeyColor).name,
      onTap: pickPubkeyColor,
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
    list.add(SettingGroupItemComponent(
      name: s.Image_service,
      value: getImageServcie(settingProvider.imageService).name,
      onTap: pickImageServcie,
    ));
    if ((settingProvider.imageService == ImageServices.NIP_96 ||
            settingProvider.imageService == ImageServices.BLOSSOM) &&
        StringUtil.isNotBlank(settingProvider.imageServiceAddr)) {
      list.add(SettingGroupItemComponent(
        name: s.Image_service_path,
        value: settingProvider.imageServiceAddr,
      ));
    }

    list.add(SettingGroupItemComponent(
      name: s.Limit_Note_Height,
      value: getOpenList(settingProvider.limitNoteHeight).name,
      onTap: pickLimitNoteHeight,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Forbid_profile_picture,
      value: getOpenList(settingProvider.profilePicturePreview).name,
      onTap: pickProfilePicturePreview,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Forbid_image,
      value: getOpenList(settingProvider.imagePreview).name,
      onTap: pickImagePreview,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Forbid_video,
      value: getOpenList(settingProvider.videoPreview).name,
      onTap: pickVideoPreview,
    ));
    if (!PlatformUtil.isWeb()) {
      list.add(SettingGroupItemComponent(
        name: "Blurhash ${s.Image}",
        value: getOpenList(settingProvider.openBlurhashImage).name,
        onTap: pickOpenBlurhashImage,
      ));
    }
    if (!PlatformUtil.isPC()) {
      list.add(SettingGroupItemComponent(
        name: s.Translate,
        value: getOpenTranslate(settingProvider.openTranslate).name,
        onTap: pickOpenTranslate,
      ));
      if (settingProvider.openTranslate == OpenStatus.OPEN) {
        list.add(SettingGroupItemComponent(
          name: s.Translate_Source_Language,
          value: settingProvider.translateSourceArgs,
          onTap: pickTranslateSource,
        ));
        list.add(SettingGroupItemComponent(
          name: s.Translate_Target_Language,
          value: settingProvider.translateTarget,
          onTap: pickTranslateTarget,
        ));
      }
    }
    list.add(SettingGroupItemComponent(
      name: s.Broadcast_When_Boost,
      value: getOpenList(settingProvider.broadcaseWhenBoost).name,
      onTap: pickBroadcaseWhenBoost,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Auto_Open_Sensitive_Content,
      value: getOpenListDefault(settingProvider.autoOpenSensitive).name,
      onTap: pickAutoOpenSensitive,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Thread_Mode,
      value: getThreadMode(settingProvider.threadMode).name,
      onTap: pickThreadMode,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Max_Sub_Notes,
      value: "${settingProvider.maxSubEventLevel ?? ""}",
      onTap: inputMaxSubNotesNumber,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Note_Client_Tag,
      value: limitText(settingProvider.noteClientTag ?? "", 20),
      onTap: inputNoteClientTag,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Note_Tail,
      value: limitText(settingProvider.noteTail ?? "", 20),
      onTap: inputNoteTail,
    ));

    list.add(
        SettingGroupTitleComponent(iconData: Icons.cloud, title: s.Network));
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
    if (!PlatformUtil.isWeb()) {
      list.add(SettingGroupItemComponent(
        name: s.LocalRelay,
        value: getOpenList(settingProvider.relayLocal).name,
        onTap: pickRelayLocal,
      ));
      list.add(SettingGroupItemComponent(
        name: s.Relay_Mode,
        value: getRelayMode(settingProvider.relayMode).name,
        onTap: pickRelayModes,
      ));
      if (settingProvider.relayMode != RelayMode.BASE_MODE) {
        list.add(SettingGroupItemComponent(
          name: s.Event_Sign_Check,
          value: getOpenListDefault(settingProvider.eventSignCheck).name,
          onTap: pickEventSignCheck,
        ));
      }
    }
    list.add(SettingGroupItemComponent(
      name: s.Hide_Relay_Notices,
      value: getOpenList(settingProvider.hideRelayNotices).name,
      onTap: pickHideRelayNotices,
    ));

    list.add(SettingGroupTitleComponent(iconData: Icons.source, title: s.Data));
    list.add(SettingGroupItemComponent(
      name: s.Remove_Cache,
      onTap: removeCache,
    ));
    list.add(SettingGroupItemComponent(
      name: s.Delete_Account,
      nameColor: Colors.red,
      onTap: askToDeleteAccount,
    ));

    list.add(SliverToBoxAdapter(
      child: Container(
        color: cardColor,
        height: 30,
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          s.Setting,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
      ),
      body: Container(
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

  EnumObj getOpenListDefault(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    return openList![1];
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

  EnumObj getLockOpenList(int lockOpen) {
    if (lockOpen == OpenStatus.OPEN) {
      return openList![0];
    }
    return openList![1];
  }

  Future<void> pickLockOpenList() async {
    List<EnumObj> newLockOpenList = [];
    newLockOpenList.add(openList![1]);

    var localAuth = LocalAuthentication();
    List<BiometricType> availableBiometrics =
        await localAuth.getAvailableBiometrics();
    if (availableBiometrics.isNotEmpty) {
      newLockOpenList.add(openList![0]);
    }

    var s = S.of(context);

    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, newLockOpenList);
    if (resultEnumObj != null) {
      if (resultEnumObj.value == OpenStatus.CLOSE) {
        bool didAuthenticate = await AuthUtil.authenticate(
            context, s.Please_authenticate_to_turn_off_the_privacy_lock);
        if (didAuthenticate) {
          settingProvider.lockOpen = resultEnumObj.value;
        }
        settingProvider.lockOpen = resultEnumObj.value;
      } else if (resultEnumObj.value == OpenStatus.OPEN) {
        bool didAuthenticate = await AuthUtil.authenticate(
            context, s.Please_authenticate_to_turn_on_the_privacy_lock);
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

  List<EnumObj>? colorStyleEnumList;

  void initColorStyleEnumList(S s) {
    if (colorStyleEnumList == null) {
      colorStyleEnumList = [];
      colorStyleEnumList!.add(EnumObj(false, s.Default_Color));
      colorStyleEnumList!.add(EnumObj(true, s.Custom_Color));
    }
  }

  Widget getCustomColorWidget(int? colorValue, TextStyle textStyle) {
    if (colorValue == null) {
      return Text(
        s.Default_Color,
        style: textStyle,
      );
    } else {
      return Container(
        height: 28,
        width: 28,
        color: Color(colorValue),
      );
    }
  }

  Future<int?> pickCustomColor({int? colorValue}) async {
    Color? oldColor;
    if (colorValue != null) {
      oldColor = Color(colorValue);
    }
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, colorStyleEnumList!);
    if (resultEnumObj != null) {
      if (resultEnumObj.value == true) {
        // pick customm color
        Color? color = await ColorPickDialog.show(context, oldColor);
        if (color != null) {
          return color.value;
        }
      } else {
        return -1;
      }
    }

    return null;
  }

  Future<void> pickMainFontColor() async {
    var colorValue =
        await pickCustomColor(colorValue: settingProvider.mainFontColor);
    if (colorValue != null) {
      if (colorValue == -1) {
        settingProvider.mainFontColor = null;
      } else {
        settingProvider.mainFontColor = colorValue;
      }
      resetTheme();
    }
  }

  Future<void> pickHintFontColor() async {
    var colorValue =
        await pickCustomColor(colorValue: settingProvider.hintFontColor);
    if (colorValue != null) {
      if (colorValue == -1) {
        settingProvider.hintFontColor = null;
      } else {
        settingProvider.hintFontColor = colorValue;
      }
      resetTheme();
    }
  }

  Future<void> pickCardColor() async {
    var colorValue =
        await pickCustomColor(colorValue: settingProvider.cardColor);
    if (colorValue != null) {
      if (colorValue == -1) {
        settingProvider.cardColor = null;
      } else {
        settingProvider.cardColor = colorValue;
      }
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FontPicker(
          onFontChanged: (PickerFont font) {
            settingProvider.fontFamily = font.fontFamily;
            resetTheme();
          },
        ),
      ),
    );
  }

  List<EnumObj> fontSizeList = [
    EnumObj(20.0, "20"),
    EnumObj(19.0, "19"),
    EnumObj(18.0, "18"),
    EnumObj(17.0, "17"),
    EnumObj(16.0, "16"),
    EnumObj(15.0, "15"),
    EnumObj(14.0, "14"),
    EnumObj(13.0, "13"),
    EnumObj(12.0, "12"),
  ];

  EnumObj getFontSize(double value) {
    for (var eo in fontSizeList) {
      if (eo.value == value) {
        return eo;
      }
    }
    return fontSizeList[1];
  }

  Future<void> pickFontSize() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, fontSizeList);
    if (resultEnumObj != null) {
      settingProvider.fontSize = resultEnumObj.value;
      resetTheme();
    }
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
      // imageServcieList!
      //     .add(EnumObj(ImageServices.NOSTRIMG_COM, ImageServices.NOSTRIMG_COM));
      // imageServcieList!.add(
      //     EnumObj(ImageServices.NOSTRFILES_DEV, ImageServices.NOSTRFILES_DEV));
      imageServcieList!
          .add(EnumObj(ImageServices.NOSTR_BUILD, ImageServices.NOSTR_BUILD));
      imageServcieList!.add(
          EnumObj(ImageServices.POMF2_LAIN_LA, ImageServices.POMF2_LAIN_LA));
      imageServcieList!.add(
          EnumObj(ImageServices.NOSTR_DOWNLOAD, ImageServices.NOSTR_DOWNLOAD));
      // imageServcieList!
      //     .add(EnumObj(ImageServices.NOSTO_RE, ImageServices.NOSTO_RE));
      imageServcieList!
          .add(EnumObj(ImageServices.VOID_CAT, ImageServices.VOID_CAT));
      imageServcieList!
          .add(EnumObj(ImageServices.NIP_95, ImageServices.NIP_95));
      imageServcieList!
          .add(EnumObj(ImageServices.NIP_96, ImageServices.NIP_96));
      imageServcieList!
          .add(EnumObj(ImageServices.BLOSSOM, ImageServices.BLOSSOM));
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
      if (resultEnumObj.value == ImageServices.NIP_96) {
        var addr = await TextInputDialog.show(
            context, "${s.Please_input} NIP-96 ${s.Image_service_path}");
        if (StringUtil.isNotBlank(addr)) {
          settingProvider.imageService = ImageServices.NIP_96;
          settingProvider.imageServiceAddr = addr;
        }
        return;
      } else if (resultEnumObj.value == ImageServices.BLOSSOM) {
        var addr = await TextInputDialog.show(
            context, "${s.Please_input} Blossom ${s.Image_service_path}");
        if (StringUtil.isNotBlank(addr)) {
          settingProvider.imageService = ImageServices.BLOSSOM;
          settingProvider.imageServiceAddr = addr;
        }
        return;
      } else if (resultEnumObj.value == ImageServices.NOSTR_DOWNLOAD) {
        settingProvider.imageService = ImageServices.BLOSSOM;
        settingProvider.imageServiceAddr = "https://nostr.download";
        return;
      }
      settingProvider.imageService = resultEnumObj.value;
    }
  }

  pickLimitNoteHeight() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.limitNoteHeight = resultEnumObj.value;
    }
  }

  pickProfilePicturePreview() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.profilePicturePreview = resultEnumObj.value;
    }
  }

  pickImagePreview() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.imagePreview = resultEnumObj.value;
    }
  }

  pickVideoPreview() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.videoPreview = resultEnumObj.value;
    }
  }

  EventMemBox waitingDeleteEventBox = EventMemBox(sortAfterAdd: false);

  CancelFunc? deleteAccountLoadingCancel;

  askToDeleteAccount() async {
    var result =
        await ConfirmDialog.show(context, S.of(context).Delete_Account_Tips);
    if (result == true) {
      deleteAccountLoadingCancel = BotToast.showLoading();
      try {
        whenStopMS = 2000;

        waitingDeleteEventBox.clear();

        // use a blank metadata to update it
        var blankMetadata = Metadata();
        var updateEvent = Event(nostr!.publicKey, EventKind.METADATA, [],
            jsonEncode(blankMetadata));
        nostr!.sendEvent(updateEvent);

        // use a blank contact list to update it
        var blankContactList = ContactList();
        nostr!.sendContactList(blankContactList, "");

        var filter = Filter(authors: [
          nostr!.publicKey
        ], kinds: [
          EventKind.TEXT_NOTE,
          EventKind.REPOST,
          EventKind.GENERIC_REPOST,
        ]);
        nostr!.query([filter.toJson()], onDeletedEventReceive);
      } catch (e) {
        log("delete account error ${e.toString()}");
      }
    }
  }

  onDeletedEventReceive(Event event) {
    print(event.toJson());
    waitingDeleteEventBox.add(event);
    whenStop(handleDeleteEvent);
  }

  void handleDeleteEvent() {
    try {
      List<Event> all = waitingDeleteEventBox.all();
      List<String> ids = [];
      for (var event in all) {
        ids.add(event.id);

        if (ids.length > 20) {
          nostr!.deleteEvents(ids);
          ids.clear();
        }
      }

      if (ids.isNotEmpty) {
        nostr!.deleteEvents(ids);
      }
    } finally {
      var index = settingProvider.privateKeyIndex;
      if (index != null) {
        AccountManagerComponentState.onLogoutTap(index,
            routerBack: true, context: context);
        metadataProvider.clear();
      } else {
        if (nostr != null) {
          nostr!.close();
        }
        nostr = null;
      }
      if (deleteAccountLoadingCancel != null) {
        deleteAccountLoadingCancel!.call();
      }
    }
  }

  List<EnumObj>? translateLanguages;

  void initTranslateLanguages() {
    if (translateLanguages == null) {
      translateLanguages = [];
      for (var tl in TranslateLanguage.values) {
        translateLanguages!.add(EnumObj(tl.bcpCode, tl.bcpCode));
      }
    }
  }

  EnumObj getOpenTranslate(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    return openList![1];
  }

  pickOpenTranslate() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      await handleTranslateModel(openTranslate: resultEnumObj.value);
      settingProvider.openTranslate = resultEnumObj.value;
    }
  }

  pickTranslateSource() async {
    var translateSourceArgs = settingProvider.translateSourceArgs;
    List<EnumObj> values = [];
    if (StringUtil.isNotBlank(translateSourceArgs)) {
      var strs = translateSourceArgs!.split(",");
      for (var str in strs) {
        values.add(EnumObj(str, str));
      }
    }
    List<EnumObj>? resultEnumObjs = await EnumMultiSelectorComponent.show(
        context, translateLanguages!, values);
    if (resultEnumObjs != null) {
      List<String> resultStrs = [];
      for (var value in resultEnumObjs) {
        resultStrs.add(value.value);
      }
      var text = resultStrs.join(",");
      await handleTranslateModel(translateSourceArgs: text);
      settingProvider.translateSourceArgs = text;
    }
  }

  pickTranslateTarget() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, translateLanguages!);
    if (resultEnumObj != null) {
      await handleTranslateModel(translateTarget: resultEnumObj.value);
      settingProvider.translateTarget = resultEnumObj.value;
    }
  }

  Future<void> handleTranslateModel(
      {int? openTranslate,
      String? translateTarget,
      String? translateSourceArgs}) async {
    openTranslate = openTranslate ?? settingProvider.openTranslate;
    translateTarget = translateTarget ?? settingProvider.translateTarget;
    translateSourceArgs =
        translateSourceArgs ?? settingProvider.translateSourceArgs;

    if (openTranslate == OpenStatus.OPEN &&
        StringUtil.isNotBlank(translateTarget) &&
        StringUtil.isNotBlank(translateSourceArgs)) {
      List<String> bcpCodes = translateSourceArgs!.split(",");
      bcpCodes.add(translateTarget!);

      var translateModelManager = TranslateModelManager.getInstance();
      BotToast.showText(text: S.of(context).Begin_to_download_translate_model);
      var cancelFunc = BotToast.showLoading();
      try {
        await translateModelManager.checkAndDownloadTargetModel(bcpCodes);
      } finally {
        cancelFunc.call();
      }
    }
  }

  pickBroadcaseWhenBoost() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.broadcaseWhenBoost = resultEnumObj.value;
    }
  }

  EnumObj getAutoOpenSensitive(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    return openList![1];
  }

  pickAutoOpenSensitive() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.autoOpenSensitive = resultEnumObj.value;
    }
  }

  pickWebviewAppbar() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.webviewAppbarOpen = resultEnumObj.value;
    }
  }

  getOpenMode(int? value) {
    for (var o in openList!) {
      if (value == o.value) {
        return o;
      }
    }

    if (PlatformUtil.isTableModeWithoutSetting()) {
      return openList![0];
    }
    return openList![1];
  }

  pickOpenMode() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.tableMode = resultEnumObj.value;
      resetTheme();
    }
  }

  List<EnumObj>? relayModes;

  List<EnumObj> getRelayModes() {
    var s = S.of(context);
    if (relayModes == null) {
      relayModes = [];
      relayModes!.add(EnumObj(RelayMode.FAST_MODE, s.Fast_Mode));
      relayModes!.add(EnumObj(RelayMode.BASE_MODE, s.Base_Mode));
    }
    return relayModes!;
  }

  EnumObj getRelayMode(int? o) {
    var list = getRelayModes();
    for (var item in list) {
      if (item.value == o) {
        return item;
      }
    }

    return list[0];
  }

  pickRelayLocal() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.relayLocal = resultEnumObj.value;
      resetTheme();
    }
  }

  pickRelayModes() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, getRelayModes());
    if (resultEnumObj != null) {
      settingProvider.relayMode = resultEnumObj.value;
    }
  }

  pickEventSignCheck() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.eventSignCheck = resultEnumObj.value;
    }
  }

  List<EnumObj>? threadModes;

  List<EnumObj> initThreadModes() {
    if (threadModes == null) {
      var s = S.of(context);
      threadModes = [];
      threadModes!.add(EnumObj(ThreadMode.FULL_MODE, s.Full_Mode));
      threadModes!.add(EnumObj(ThreadMode.TRACE_MODE, s.Trace_Mode));
    }

    return threadModes!;
  }

  getThreadMode(int? o) {
    for (var eo in threadModes!) {
      if (eo.value == o) {
        return eo;
      }
    }
    return threadModes![1];
  }

  pickThreadMode() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, initThreadModes());
    if (resultEnumObj != null) {
      settingProvider.threadMode = resultEnumObj.value;
    }
  }

  inputMaxSubNotesNumber() async {
    var numText = await TextInputDialog.show(
        context, S.of(context).Please_input_the_max_sub_notes_number);
    if (StringUtil.isNotBlank(numText)) {
      var num = int.tryParse(numText!);
      if (num != null && num <= 0) {
        num = null;
      }
      settingProvider.maxSubEventLevel = num;
    }
  }

  pickHideRelayNotices() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.hideRelayNotices = resultEnumObj.value;
    }
  }

  pickBackgroundImage() async {
    var filepath = await Uploader.pick(context);
    if (StringUtil.isBlank(filepath)) {
      settingProvider.backgroundImage = null;
    } else {
      if (PlatformUtil.isWeb()) {
        var uploadedFilepath = await Uploader.upload(filepath!,
            imageService: settingProvider.imageService);
        settingProvider.backgroundImage = uploadedFilepath;
      } else {
        var targetFilePath = await StoreUtil.saveFileToDocument(filepath!,
            targetFileName:
                "nostrbg_${DateTime.now().millisecondsSinceEpoch}.jpg");
        if (StringUtil.isNotBlank(targetFilePath)) {
          if (StringUtil.isNotBlank(settingProvider.backgroundImage)) {
            // try to remove old file.
            try {
              var targetFile = File(settingProvider.backgroundImage!);
              if (targetFile.existsSync()) {
                targetFile.deleteSync();
              }
            } catch (e) {}
          }
          settingProvider.backgroundImage = targetFilePath;
          settingProvider.translateTarget = null;
        }
      }
    }

    resetTheme();
  }

  pickOpenBlurhashImage() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.openBlurhashImage = resultEnumObj.value;
    }
  }

  pickPubkeyColor() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.pubkeyColor = resultEnumObj.value;
    }
  }

  pickWotFilter() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.wotFilter = resultEnumObj.value;

      if (settingProvider.wotFilter == OpenStatus.OPEN) {
        var pubkey = nostr!.publicKey;
        wotProvider.init(pubkey);
      } else {
        wotProvider.clear();
      }
    }
  }

  pickMentionNoteNotice() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.mentionNoteNotice = resultEnumObj.value;
    }
  }

  pickFollowNoteNotice() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.followNoteNotice = resultEnumObj.value;
    }
  }

  pickMessageNotice() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      settingProvider.messageNotice = resultEnumObj.value;
    }
  }

  inputNoteClientTag() async {
    var text = await TextInputDialog.show(context, s.Note_Client_Tag,
        value: settingProvider.noteClientTag ?? "",
        des: s.Note_Client_Tag_Des, valueCheck: (context, text) {
      if (StringUtil.isNotBlank(text) && text.length > 20) {
        BotToast.showText(text: s.Input_too_long);
        return false;
      }

      return true;
    });
    settingProvider.noteClientTag = text;
  }

  inputNoteTail() async {
    var text = await TextInputDialog.show(context, s.Note_Tail,
        value: settingProvider.noteTail ?? "",
        des: s.Note_Tail_Des, valueCheck: (context, text) {
      if (StringUtil.isNotBlank(text) && text.length > 200) {
        BotToast.showText(text: s.Input_too_long);
        return false;
      }

      return true;
    });

    if (text != null) {
      settingProvider.noteTail = text;
    }
  }

  String limitText(String text, int length) {
    text = text.replaceAll("\n", " ");
    if (text.length > length) {
      return "${text.substring(0, 18)} ...";
    }

    return text;
  }

  removeCache() {
    CacheRemoveDialog.show(context);
  }

  pickTagsSpamFilter() async {
    EnumObj? resultEnumObj =
        await EnumSelectorComponent.show(context, openList!);
    if (resultEnumObj != null) {
      if (resultEnumObj.value == OpenStatus.OPEN) {
        filterProvider.updateTagsSpamNum(8);
      } else {
        filterProvider.updateTagsSpamNum(-1);
      }
    }
  }

  pickTagsSpamFilterNumber() async {
    List<EnumObj>? list = [
      EnumObj(3, "3"),
      EnumObj(4, "4"),
      EnumObj(5, "5"),
      EnumObj(6, "6"),
      EnumObj(7, "7"),
      EnumObj(8, "8"),
      EnumObj(9, "9"),
      EnumObj(10, "10"),
      EnumObj(11, "11"),
      EnumObj(12, "12"),
      EnumObj(13, "13"),
      EnumObj(14, "14"),
    ];
    EnumObj? resultEnumObj = await EnumSelectorComponent.show(context, list);
    if (resultEnumObj != null) {
      filterProvider.updateTagsSpamNum(resultEnumObj.value);
    }
  }
}
