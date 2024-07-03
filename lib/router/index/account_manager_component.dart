import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip46/nostr_remote_signer_info.dart';
import 'package:nostrmo/client/nip55/android_nostr_signer.dart';
import 'package:nostrmo/component/editor/text_input_dialog.dart';
import 'package:nostrmo/component/user/name_component.dart';
import 'package:nostrmo/component/point_component.dart';
import 'package:nostrmo/component/user/user_pic_component.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../client/client_utils/keys.dart';
import '../../client/nip19/nip19.dart';
import '../../component/confirm_dialog.dart';
import '../../component/image_component.dart';
import '../../consts/base.dart';
import '../../data/dm_session_info_db.dart';
import '../../data/event_db.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/string_util.dart';
import 'index_drawer_content.dart';

class AccountManagerComponent extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AccountManagerComponentState();
  }
}

class AccountManagerComponentState extends State<AccountManagerComponent> {
  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var _settingProvider = Provider.of<SettingProvider>(context);
    var privateKeyMap = _settingProvider.privateKeyMap;

    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var btnTextColor = themeData.textTheme.bodyMedium!.color;

    List<Widget> list = [];
    list.add(Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: hintColor,
          ),
        ),
      ),
      child: IndexDrawerItem(
        iconData: Icons.account_box,
        name: s.Account_Manager,
        onTap: () {},
      ),
    ));

    privateKeyMap.forEach((key, value) {
      var index = int.tryParse(key);
      if (index == null) {
        log("parse index key error");
        return;
      }
      list.add(AccountManagerItemComponent(
        index: index,
        accountKey: value,
        isCurrent: _settingProvider.privateKeyIndex == index,
        onLoginTap: onLoginTap,
        onLogoutTap: (index) {
          onLogoutTap(index, context: context);
        },
      ));
    });

    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING * 2,
        right: Base.BASE_PADDING * 2,
      ),
      width: double.maxFinite,
      child: TextButton(
        onPressed: addAccount,
        style: ButtonStyle(
          side: MaterialStateProperty.all(BorderSide(
            width: 1,
            color: hintColor.withOpacity(0.4),
          )),
        ),
        child: Text(
          s.Add_Account,
          style: TextStyle(color: btnTextColor),
        ),
      ),
    ));

    return Container(
      // height: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }

  Future<void> addAccount() async {
    var privateKey = await TextInputDialog.show(
        context, S.of(context).Input_account_private_key,
        valueCheck: addAccountCheck);
    if (StringUtil.isNotBlank(privateKey)) {
      var result = await ConfirmDialog.show(
          context, S.of(context).Add_account_and_login);
      if (result == true) {
        if (Nip19.isPrivateKey(privateKey!)) {
          privateKey = Nip19.decode(privateKey);
        }
        // logout current and login new
        var oldIndex = settingProvider.privateKeyIndex;
        var newIndex = settingProvider.addAndChangePrivateKey(privateKey);
        if (oldIndex != newIndex) {
          clearCurrentMemInfo();
          doLogin();
          settingProvider.notifyListeners();
          RouterUtil.back(context);
        }
      }
    }
  }

  bool addAccountCheck(BuildContext p1, String privateKey) {
    if (StringUtil.isNotBlank(privateKey)) {
      if (Nip19.isPrivateKey(privateKey)) {
        privateKey = Nip19.decode(privateKey);
      }

      // try to gen publicKey check the formate
      try {
        getPublicKey(privateKey);
      } catch (e) {
        BotToast.showText(text: S.of(context).Wrong_Private_Key_format);
        return false;
      }
    }

    return true;
  }

  Future<void> doLogin() async {
    nostr = await relayProvider.genNostrWithKey(settingProvider.privateKey!);
  }

  void onLoginTap(int index) {
    if (settingProvider.privateKeyIndex != index) {
      clearCurrentMemInfo();
      nostr!.close();
      nostr = null;

      settingProvider.privateKeyIndex = index;

      // signOut complete
      if (settingProvider.privateKey != null) {
        // use next privateKey to login
        doLogin();
        settingProvider.notifyListeners();
        RouterUtil.back(context);
      }
    }
  }

  static Future<void> onLogoutTap(int index,
      {bool routerBack = true, BuildContext? context}) async {
    var oldIndex = settingProvider.privateKeyIndex;
    clearLocalData(index);

    if (oldIndex == index) {
      clearCurrentMemInfo();
      nostr!.close();
      nostr = null;

      // signOut complete
      if (settingProvider.privateKey != null) {
        // use next privateKey to login
        nostr =
            await relayProvider.genNostrWithKey(settingProvider.privateKey!);
      }
    }

    settingProvider.notifyListeners();
    if (routerBack && context != null) {
      RouterUtil.back(context);
    }
  }

  static void clearCurrentMemInfo() {
    mentionMeProvider.clear();
    mentionMeNewProvider.clear();
    followEventProvider.clear();
    followNewEventProvider.clear();
    dmProvider.clear();
    noticeProvider.clear();
    contactListProvider.clear();

    eventReactionsProvider.clear();
    linkPreviewDataProvider.clear();
    relayProvider.clear();
    listProvider.clear();
  }

  static void clearLocalData(int index) {
    // remove private key
    settingProvider.removeKey(index);
    // clear local db
    DMSessionInfoDB.deleteAll(index);
    EventDB.deleteAll(index);
    // MetadataDB.deleteAll(); // MetadataDB don't delete here, but delete in setting
  }
}

class AccountManagerItemComponent extends StatefulWidget {
  bool isCurrent;

  int index;

  String accountKey;

  Function(int)? onLoginTap;

  Function(int)? onLogoutTap;

  AccountManagerItemComponent({
    required this.isCurrent,
    required this.index,
    required this.accountKey,
    this.onLoginTap,
    this.onLogoutTap,
  });

  @override
  State<StatefulWidget> createState() {
    return _AccountManagerItemComponent();
  }
}

class _AccountManagerItemComponent extends State<AccountManagerItemComponent> {
  static const double IMAGE_WIDTH = 26;

  static const double LINE_HEIGHT = 44;

  late String pubkey;

  @override
  void initState() {
    super.initState();
    if (Nip19.isPubkey(widget.accountKey)) {
      pubkey = Nip19.decode(widget.accountKey);
    } else if (AndroidNostrSigner.isAndroidNostrSignerKey(widget.accountKey)) {
      pubkey = AndroidNostrSigner.getPubkey(widget.accountKey);
    } else if (NostrRemoteSignerInfo.isBunkerUrl(widget.accountKey)) {
      var info = NostrRemoteSignerInfo.parseBunkerUrl(widget.accountKey);
      if (info != null) {
        pubkey = info.remoteUserPubkey;
      } else {
        pubkey = "";
      }
    } else {
      pubkey = getPublicKey(widget.accountKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    Color? cardColor = themeData.cardColor;
    if (cardColor == Colors.white) {
      cardColor = Colors.grey[300];
    }

    return Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
      Color currentColor = Colors.green;
      List<Widget> list = [];

      var nip19PubKey = Nip19.encodePubKey(pubkey);

      list.add(Container(
        width: 24,
        alignment: Alignment.centerLeft,
        child: Container(
          width: 15,
          child: widget.isCurrent
              ? PointComponent(
                  width: 15,
                  color: currentColor,
                )
              : null,
        ),
      ));

      list.add(UserPicComponent(
        pubkey: pubkey,
        width: IMAGE_WIDTH,
        metadata: metadata,
      ));

      list.add(Container(
        margin: EdgeInsets.only(left: 5, right: 5),
        child: NameComponent(
          pubkey: pubkey,
          metadata: metadata,
        ),
      ));

      list.add(Expanded(
          child: Container(
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING_HALF,
          right: Base.BASE_PADDING_HALF,
          top: 4,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          nip19PubKey,
          overflow: TextOverflow.ellipsis,
        ),
      )));

      list.add(GestureDetector(
        onTap: onLogout,
        child: Container(
          padding: EdgeInsets.only(left: 5),
          height: LINE_HEIGHT,
          child: Icon(Icons.logout),
        ),
      ));

      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Container(
          height: LINE_HEIGHT,
          width: double.maxFinite,
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING * 2,
            right: Base.BASE_PADDING * 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: list,
          ),
        ),
      );
    }, selector: (context, _provider) {
      return _provider.getMetadata(pubkey);
    });
  }

  void onLogout() {
    if (widget.onLogoutTap != null) {
      widget.onLogoutTap!(widget.index);
    }
  }

  void onTap() {
    if (widget.onLoginTap != null) {
      widget.onLoginTap!(widget.index);
    }
  }
}
