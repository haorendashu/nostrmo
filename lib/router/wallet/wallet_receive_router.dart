import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostr_sdk/zap/zap.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/router_util.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../generated/l10n.dart';

class WalletReceiveRouter extends StatefulWidget {
  WalletReceiveRouter({super.key});

  @override
  State<WalletReceiveRouter> createState() => _WalletReceiveRouterState();
}

class _WalletReceiveRouterState extends State<WalletReceiveRouter> {
  String lud16 = "";

  TextEditingController numController = TextEditingController();

  TextEditingController commentController = TextEditingController();

  late S s;

  @override
  Widget build(BuildContext context) {
    var arg = RouterUtil.routerArgs(context);
    if (arg == null && arg is! String) {
      RouterUtil.back(context);
      return Container();
    }
    lud16 = arg as String;

    s = S.of(context);
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    var numberSize = 30.0;

    List<Widget> list = [];

    List<Widget> inputList = [];
    inputList.add(Container(
      child: TextField(
        autofocus: true,
        controller: numController,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "0",
          hintStyle: TextStyle(
            fontSize: numberSize,
            fontWeight: FontWeight.bold,
            color: themeData.hintColor,
          ),
        ),
        style: TextStyle(
          fontSize: numberSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
    inputList.add(Container(
      child: const Text("sats"),
    ));
    inputList.add(Container(
      margin: EdgeInsets.only(top: 26),
      child: Text(s.Comment),
    ));
    inputList.add(Container(
      child: TextField(
        controller: commentController,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "( ${s.Optional} )",
          hintStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeData.hintColor,
          ),
        ),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    list.add(Expanded(
        child: Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: inputList,
      ),
    )));

    List<Widget> bottomList = [];
    bottomList.add(
        FilledButton(onPressed: genInvoice, child: Text(s.Generate_Invoice)));
    bottomList.add(Container(
      margin: EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      child: Divider(),
    ));
    bottomList.add(FilledButton(onPressed: qrCode, child: Text(s.QrCode)));
    list.add(Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: bottomList,
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          s.Generate_Invoice,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: list,
      ),
    );
  }

  Future<void> genInvoice() async {
    var numText = numController.text;
    if (StringUtil.isBlank(numText)) {
      return;
    }

    var num = int.tryParse(numText);
    if (num == null) {
      return;
    }

    var comment = commentController.text;

    var lnurl = Zap.getLnurlFromLud16(lud16);
    if (StringUtil.isBlank(lnurl)) {
      BotToast.showText(text: "Lnurl ${s.not_found}");
      return;
    }
    var lud16Link = Zap.getLud16LinkFromLud16(lud16);
    if (StringUtil.isBlank(lnurl)) {
      BotToast.showText(text: "lud16 link ${s.not_found}");
      return;
    }

    var cancelFunc = BotToast.showLoading();
    try {
      var recipientPubkey = nostr!.publicKey;
      var readRelays = metadataProvider.getExtralRelays(recipientPubkey, false);

      var invoice = await Zap.getInvoiceCode(
          lnurl: lnurl!,
          lud16Link: lud16Link!,
          sats: num,
          comment: comment,
          recipientPubkey: recipientPubkey,
          targetNostr: nostr!,
          relays: readRelays);

      RouterUtil.back(context, invoice);
    } finally {
      cancelFunc.call();
    }
  }

  void qrCode() {
    RouterUtil.back(context, lud16);
  }
}
