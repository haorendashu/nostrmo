import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostr_sdk/zap/zap.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/wallet/zap_info_input_component.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/zap_action.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';

class WalletSendRotuer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _WalletSendRotuer();
  }
}

class _WalletSendRotuer extends CustState<WalletSendRotuer> {
  TextEditingController addressController = TextEditingController();

  TextEditingController numController = TextEditingController();

  TextEditingController commentController = TextEditingController();

  late S s;

  bool inputingZapInfo = false;

  @override
  Widget doBuild(BuildContext context) {
    s = S.of(context);
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];

    if (inputingZapInfo) {
      list.add(Expanded(
          child: Container(
        alignment: Alignment.center,
        child: ZapInfoInputComponent(numController, commentController),
      )));

      List<Widget> bottomList = [];
      bottomList.add(FilledButton(onPressed: send, child: Text(s.Send)));
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
    } else {
      List<Widget> inputList = [];
      inputList.add(Container(
        child: Text(s.Wallet_send_tips),
      ));
      inputList.add(Container(
        child: TextField(
          autofocus: true,
          controller: addressController,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "username@getably.com",
            hintStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: themeData.hintColor,
            ),
          ),
          style: TextStyle(
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
      bottomList.add(FilledButton(onPressed: next, child: Text(s.Next)));
      bottomList.add(Container(
        margin: EdgeInsets.only(
          top: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: Divider(),
      ));
      bottomList.add(FilledButton(onPressed: scan, child: Text(s.Scan)));
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
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          s.Send_Zap,
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

  @override
  Future<void> onReady(BuildContext context) async {}

  Future<void> scan() async {
    var result = await RouterUtil.router(context, RouterPath.QRSCANNER);
    if (StringUtil.isNotBlank(result)) {
      addressController.text = result;
    }
  }

  String? lud16Link;

  String? lnurl;

  String? recipientPubkey;

  List<String>? relays;

  void next() {
    var text = addressController.text;
    if (text.contains("@")) {
      lud16Link = Zap.getLud16LinkFromLud16(text);
      lnurl = Zap.getLnurlFromLud16(text);
    } else if (text.startsWith("LNURL")) {
      lnurl = text;
      lud16Link = Zap.decodeLud06Link(text);
    } else if (text.startsWith("lnbc")) {
      nwcProvider.sendZap(context, text);
      RouterUtil.back(context);
      return;
    }

    setState(() {
      inputingZapInfo = true;
    });
  }

  Future<void> send() async {
    var num = int.tryParse(numController.text);
    if (num == null) {
      BotToast.showText(text: s.Number_parse_error);
      return;
    }
    var comment = commentController.text;

    var cancelFunc = BotToast.showLoading();

    try {
      var invoiceCode = await Zap.getInvoiceCode(
          lnurl: lnurl!,
          lud16Link: lud16Link!,
          sats: num,
          recipientPubkey: null,
          targetNostr: nostr!,
          relays: null,
          comment: comment);

      if (StringUtil.isBlank(invoiceCode)) {
        return;
      }

      nwcProvider.sendZap(context, invoiceCode!);
    } finally {
      cancelFunc.call();
    }
  }
}
