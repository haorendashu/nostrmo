import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nostr_sdk/android_plugin/android_plugin.dart';
import 'package:nostr_sdk/client_utils/keys.dart';
import 'package:nostr_sdk/nip05/nip05_validor.dart';
import 'package:nostr_sdk/nip07/nip07_signer.dart';
import 'package:nostr_sdk/nip19/nip19.dart';
import 'package:nostr_sdk/nip46/nostr_remote_signer.dart';
import 'package:nostr_sdk/nip46/nostr_remote_signer_info.dart';
import 'package:nostr_sdk/nip55/android_nostr_signer.dart';
import 'package:nesigner_adapter/nesigner_adapter.dart';
import 'package:nostr_sdk/signer/pubkey_only_nostr_signer.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostrmo/component/webview_router.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:hex/hex.dart';

import '../../component/nesigner_login_dialog.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../../util/table_mode_util.dart';
import '../index/account_manager_component.dart';

class LoginRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginRouter();
  }
}

class _LoginRouter extends State<LoginRouter>
    with SingleTickerProviderStateMixin {
  bool? checkTerms = false;

  bool obscureText = true;

  TextEditingController controller = TextEditingController();

  late AnimationController animationController;

  bool existAndroidNostrSigner = false;

  bool existWebNostrSigner = false;

  bool existNesigner = false;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    if (PlatformUtil.isAndroid()) {
      AndroidPlugin.existAndroidNostrSigner().then((exist) {
        if (exist == true) {
          setState(() {
            existAndroidNostrSigner = true;
          });
        }
      });
    } else if (PlatformUtil.isWeb()) {
      if (NIP07Signer.support()) {
        setState(() {
          existWebNostrSigner = true;
        });
      }
    }

    if (!PlatformUtil.isIOS() && !Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkNesigner();
      });
    }
  }

  void checkNesigner() {
    try {
      var exist = NesignerUtil.nesignerExist();
      setState(() {
        existNesigner = exist;
      });
    } catch (e) {
      print("checkNesigner error $e");
    }
  }

  bool backAfterLogin = false;

  late S s;

  @override
  Widget build(BuildContext context) {
    s = S.of(context);
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var maxWidth = mediaDataCache.size.width;
    var mainWidth = maxWidth * 0.8;
    if (TableModeUtil.isTableMode()) {
      if (mainWidth > 550) {
        mainWidth = 550;
      }
    }

    var logoWiget = Image.asset(
      "assets/imgs/logo/logo512.png",
      width: 100,
      height: 100,
    );

    var arg = RouterUtil.routerArgs(context);
    if (arg != null && arg is bool) {
      backAfterLogin = arg;
    }

    List<Widget> mainList = [];
    mainList.add(logoWiget);
    mainList.add(Container(
      margin: EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: 40,
      ),
      child: Text(
        Base.APP_NAME,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    var suffixIcon = GestureDetector(
      onTap: () {
        setState(() {
          obscureText = !obscureText;
        });
      },
      child: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
    );
    mainList.add(TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: "nsec / hex private key / npub / NIP-05 Address / bunker://",
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
      ),
      obscureText: obscureText,
    ));

    mainList.add(Container(
      margin: EdgeInsets.all(Base.BASE_PADDING * 2),
      child: InkWell(
        onTap: doLogin,
        child: Container(
          height: 36,
          color: mainColor,
          alignment: Alignment.center,
          child: Text(
            s.Login,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ));

    mainList.add(Container(
      margin: EdgeInsets.only(bottom: 25),
      child: GestureDetector(
        onTap: generatePK,
        child: Text(
          s.Generate_a_new_private_key,
          style: TextStyle(
            color: mainColor,
            decoration: TextDecoration.underline,
            decorationColor: mainColor,
          ),
        ),
      ),
    ));

    if (PlatformUtil.isAndroid() && existAndroidNostrSigner) {
      mainList.add(Container(
        child: Text(s.or),
      ));

      mainList.add(Container(
        margin: const EdgeInsets.all(Base.BASE_PADDING * 2),
        child: InkWell(
          onTap: loginByAndroidSigner,
          child: Container(
            height: 36,
            color: mainColor,
            alignment: Alignment.center,
            child: Text(
              s.Login_With_Android_Signer,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ));
    } else if (PlatformUtil.isWeb() && existWebNostrSigner) {
      mainList.add(Container(
        child: Text(s.or),
      ));

      mainList.add(Container(
        margin: const EdgeInsets.all(Base.BASE_PADDING * 2),
        child: InkWell(
          onTap: loginWithWebSigner,
          child: Container(
            height: 36,
            color: mainColor,
            alignment: Alignment.center,
            child: Text(
              s.Login_With_NIP07_Extension,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ));
    }
    if (existNesigner) {
      mainList.add(Container(
        child: Text(s.or),
      ));

      mainList.add(Container(
        margin: const EdgeInsets.all(Base.BASE_PADDING * 2),
        child: InkWell(
          onTap: loginByNesigner,
          child: Container(
            height: 36,
            color: mainColor,
            alignment: Alignment.center,
            child: Text(
              "Login with Nesigner",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ));
    }

    var termsWiget = Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
              value: checkTerms,
              onChanged: (val) {
                setState(() {
                  checkTerms = val;
                });
              }),
          Text("${s.I_accept_the} "),
          Container(
            child: GestureDetector(
              onTap: () {
                WebViewRouter.open(context, Base.PRIVACY_LINK);
              },
              child: Text(
                s.terms_of_user,
                style: TextStyle(
                  color: mainColor,
                  decoration: TextDecoration.underline,
                  decorationColor: mainColor,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(controller: animationController, effects: [
      ShakeEffect(),
    ]);

    return Scaffold(
      body: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Container(
              width: mainWidth,
              // color: Colors.red,
              child: Column(
                children: mainList,
                mainAxisSize: MainAxisSize.min,
              ),
            ),
            Positioned(
              bottom: 20,
              child: termsWiget,
            ),
          ],
        ),
      ),
    );
  }

  void generatePK() {
    var pk = generatePrivateKey();
    controller.text = pk;

    // mark newUser and will show follow suggest after login.
    newUser = true;
  }

  Future<void> doLogin() async {
    if (checkTerms != true) {
      tipAcceptTerm();
      return;
    }

    var pk = controller.text;
    if (StringUtil.isBlank(pk)) {
      BotToast.showText(text: S.of(context).Input_can_not_be_null);
      return;
    }

    if (Nip19.isPubkey(pk) || pk.indexOf("@") > 0) {
      String? pubkey;
      if (Nip19.isPubkey(pk)) {
        pubkey = Nip19.decode(pk);
      } else if (pk.indexOf("@") > 0) {
        // try to find pubkey first.
        var cancelFunc = BotToast.showLoading();
        try {
          pubkey = await Nip05Validor.getPubkey(pk);
        } catch (e) {
          print("doLogin error ${e.toString()}");
        } finally {
          cancelFunc.call();
        }
      }

      if (StringUtil.isBlank(pubkey)) {
        BotToast.showText(text: "${s.Pubkey} ${s.not_found}");
        return;
      }

      doPreLogin();

      var npubKey = Nip19.encodePubKey(pubkey!);
      settingProvider.addAndChangePrivateKey(npubKey, updateUI: false);

      var pubkeyOnlySigner = PubkeyOnlyNostrSigner(pubkey);
      nostr = await relayProvider.genNostr(pubkeyOnlySigner);
      BotToast.showText(text: s.Readonly_login_tip);
    } else if (NostrRemoteSignerInfo.isBunkerUrl(pk)) {
      var cancel = BotToast.showLoading();
      try {
        var info = NostrRemoteSignerInfo.parseBunkerUrl(pk);
        if (info == null) {
          return;
        }

        var bunkerLink = info.toString();

        // var nostrRemoteSigner = NostrRemoteSigner(info);
        // await nostrRemoteSigner.connect();
        // signerTest(nostrRemoteSigner);
        nostr = await relayProvider.genNostrWithKey(bunkerLink);
        if (nostr != null && nostr!.nostrSigner is NostrRemoteSigner) {
          bunkerLink =
              (nostr!.nostrSigner as NostrRemoteSigner).info.toString();
        }
        settingProvider.addAndChangePrivateKey(bunkerLink, updateUI: false);
      } finally {
        cancel.call();
      }
    } else {
      if (Nip19.isPrivateKey(pk)) {
        pk = Nip19.decode(pk);
      }

      try {
        getPublicKey(pk);
      } catch (e) {
        // is not a private key
        BotToast.showText(text: S.of(context).Wrong_Private_Key_format);
        return;
      }

      doPreLogin();

      settingProvider.addAndChangePrivateKey(pk, updateUI: false);
      nostr = await relayProvider.genNostrWithKey(pk);
    }

    if (backAfterLogin) {
      RouterUtil.back(context);
    }

    settingProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(1);
  }

  void tipAcceptTerm() {
    BotToast.showText(text: S.of(context).Please_accept_the_terms);
    animationController.reset();
    animationController.forward();
  }

  Future<void> loginByAndroidSigner() async {
    if (checkTerms != true) {
      tipAcceptTerm();
      return;
    }

    var androidNostrSigner = AndroidNostrSigner();
    var pubkey = await androidNostrSigner.getPublicKey();
    if (StringUtil.isBlank(pubkey)) {
      BotToast.showText(text: s.Login_fail);
      return;
    }

    doPreLogin();

    var key = "${AndroidNostrSigner.URI_PRE}:$pubkey";
    if (StringUtil.isNotBlank(androidNostrSigner.getPackage())) {
      key = "$key?package=${androidNostrSigner.getPackage()}";
    }
    settingProvider.addAndChangePrivateKey(key, updateUI: false);
    nostr = await relayProvider.genNostr(androidNostrSigner);

    if (backAfterLogin) {
      RouterUtil.back(context);
    }

    settingProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(1);
  }

  Future<void> loginWithWebSigner() async {
    if (checkTerms != true) {
      tipAcceptTerm();
      return;
    }

    var signer = NIP07Signer();
    var pubkey = await signer.getPublicKey();
    if (StringUtil.isBlank(pubkey)) {
      BotToast.showText(text: s.Login_fail);
      return;
    }

    doPreLogin();

    var key = "${NIP07Signer.URI_PRE}:$pubkey";
    settingProvider.addAndChangePrivateKey(key, updateUI: false);
    nostr = await relayProvider.genNostr(signer);

    if (backAfterLogin) {
      RouterUtil.back(context);
    }

    settingProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(1);
  }

  Future<void> loginByNesigner() async {
    if (checkTerms != true) {
      tipAcceptTerm();
      return;
    }

    var nesignerInputStr = await NesignerLoginDialog.show(context);
    if (nesignerInputStr == null) {
      return;
    }

    var strs = nesignerInputStr.split(":");
    var aesKey = strs[0];

    var cancelFunc = BotToast.showLoading();

    try {
      var nesigner = Nesigner(aesKey);
      if (!(await nesigner.start())) {
        BotToast.showText(text: "Connect to nesigner fail.");
        return;
      }

      if (strs.length > 1) {
        var privateKey = strs[1];
        var aesKeyBin = HEX.decode(aesKey);
        var updateResult =
            await nesigner.updateKey(Uint8List.fromList(aesKeyBin), privateKey);
        print("update result $updateResult");
      }

      var pubkey = await nesigner.getPublicKey();
      if (StringUtil.isBlank(pubkey)) {
        try {
          // login fail, should close the signer.
          nesigner.close();
        } catch (e) {
          print("getPublicKey error $e");
        }
        BotToast.showText(text: s.Login_fail);
        return;
      }

      doPreLogin();

      var key = "${Nesigner.URI_PRE}:$aesKey?pubkey=$pubkey";
      settingProvider.addAndChangePrivateKey(key, updateUI: false);
      nostr = await relayProvider.genNostr(nesigner);
    } finally {
      cancelFunc.call();
    }

    if (backAfterLogin) {
      RouterUtil.back(context);
    }

    settingProvider.notifyListeners();
    indexProvider.setCurrentTap(1);
  }

  void doPreLogin() {
    if (backAfterLogin) {
      AccountManagerComponentState.clearCurrentMemInfo();
      if (nostr != null) {
        nostr!.close();
      }
      nostr = null;
    }
  }
}
