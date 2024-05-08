import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nostrmo/component/webview_router.dart';
import 'package:nostrmo/util/platform_util.dart';

import '../../client/client_utils/keys.dart';
import '../../client/nip19/nip19.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/string_util.dart';

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

  @override
  void initState() {
    animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    // animation = ;
  }

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var maxWidth = mediaDataCache.size.width;
    var mainWidth = maxWidth * 0.8;
    if (PlatformUtil.isTableMode()) {
      if (mainWidth > 550) {
        mainWidth = 550;
      }
    }

    var logoWiget = Image.asset(
      "assets/imgs/logo/logo512.png",
      width: 100,
      height: 100,
    );

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
        hintText: "nsec / hex private key",
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
      margin: EdgeInsets.only(bottom: 100),
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
          Text(s.I_accept_the + " "),
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
      BotToast.showText(text: S.of(context).Private_key_is_null);
      return;
    }

    // var cancelFunc = BotToast.showLoading();
    // try {
    if (Nip19.isPrivateKey(pk)) {
      pk = Nip19.decode(pk);
    }
    settingProvider.addAndChangePrivateKey(pk, updateUI: false);
    nostr = relayProvider.genNostr(pk);
    //   await Future.delayed(Duration(seconds: 5));
    // } finally {
    //   cancelFunc.call();
    // }

    settingProvider.notifyListeners();
    firstLogin = true;
    indexProvider.setCurrentTap(1);
  }

  void tipAcceptTerm() {
    BotToast.showText(text: S.of(context).Please_accept_the_terms);
    animationController.reset();
    animationController.forward();
  }
}
