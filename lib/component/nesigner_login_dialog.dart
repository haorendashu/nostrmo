import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:nostr_sdk/nip19/nip19.dart';
import 'package:nesigner_adapter/nesigner_adapter.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../main.dart';
import '../util/hash_util.dart';
import '../util/router_util.dart';
import '../util/table_mode_util.dart';
import '../util/theme_util.dart';

class NesignerLoginDialog extends StatefulWidget {
  NesignerLoginDialog();

  static Future<String?> show(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (_context) {
        return NesignerLoginDialog();
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _NesignerLoginDialog();
  }
}

class _NesignerLoginDialog extends State<NesignerLoginDialog> {
  TextEditingController controller = TextEditingController();

  TextEditingController controller1 = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  bool obscureText = true;

  bool obscureText1 = true;

  bool bingKey = false;

  late S s;

  @override
  Widget build(BuildContext context) {
    s = S.of(context);
    var themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;
    var textColor = themeData.textTheme.bodyMedium!.color;

    List<Widget> list = [];
    var suffixIcon = GestureDetector(
      onTap: () {
        setState(() {
          obscureText = !obscureText;
        });
      },
      child: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
    );
    list.add(Container(
      margin: EdgeInsets.only(
        left: Base.BASE_PADDING_HALF,
        right: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING,
        top: Base.BASE_PADDING * 2,
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: "Please input Pin",
          fillColor: Colors.white,
          suffixIcon: suffixIcon,
        ),
        obscureText: obscureText,
      ),
    ));

    if (bingKey) {
      var suffixIcon1 = GestureDetector(
        onTap: () {
          setState(() {
            obscureText1 = !obscureText1;
          });
        },
        child: Icon(obscureText1 ? Icons.visibility : Icons.visibility_off),
      );
      list.add(Container(
        margin: EdgeInsets.only(
          left: Base.BASE_PADDING_HALF,
          right: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING,
          top: Base.BASE_PADDING_HALF,
        ),
        child: TextField(
          controller: controller1,
          decoration: InputDecoration(
            hintText: "Please input private key",
            fillColor: Colors.white,
            suffixIcon: suffixIcon1,
          ),
          obscureText: obscureText1,
        ),
      ));
    }

    list.add(Container(
      margin: const EdgeInsets.only(
        left: Base.BASE_PADDING_HALF,
        right: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING,
        top: Base.BASE_PADDING,
      ),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: doLogin,
          highlightColor: mainColor.withOpacity(0.2),
          child: Container(
            color: mainColor,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              bingKey ? "Bind and Login" : "Login",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ));

    list.add(Container(
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING),
      child: GestureDetector(
        onTap: switchBingKey,
        child: Text(
          bingKey ? "Direct Login" : "Bind Private Key",
          style: TextStyle(
            color: mainColor,
            decoration: TextDecoration.underline,
            decorationColor: mainColor,
          ),
        ),
      ),
    ));

    var main = Container(
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        color: cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );

    if (PlatformUtil.isPC() || TableModeUtil.isTableMode()) {
      main = Container(
        width: mediaDataCache.size.width / 2,
        child: main,
      );
    }

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }

  void switchBingKey() {
    setState(() {
      bingKey = !bingKey;
    });
  }

  void doLogin() {
    var pin = controller.text;
    var privateKey = controller1.text;

    if (StringUtil.isBlank(pin)) {
      BotToast.showText(text: s.Input_can_not_be_null);
      return;
    }

    var aesKey = HashUtil.md5(pin);

    if (bingKey) {
      if (StringUtil.isBlank(privateKey)) {
        BotToast.showText(text: s.Input_can_not_be_null);
        return;
      }

      if (Nip19.isPrivateKey(privateKey)) {
        privateKey = Nip19.decode(privateKey);
      }

      return RouterUtil.back(context, "$aesKey:$privateKey");
    }

    return RouterUtil.back(context, aesKey);
  }
}
