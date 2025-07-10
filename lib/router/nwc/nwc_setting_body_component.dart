import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip47/nwc_info.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/colors_util.dart';
import '../../util/router_util.dart';
import '../../util/table_mode_util.dart';

class NwcSettingBodyComponent extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NwcSettingBodyComponentState();
  }
}

class NwcSettingBodyComponentState extends CustState<NwcSettingBodyComponent> {
  TextEditingController textEditingController = TextEditingController();

  @override
  Future<void> onReady(BuildContext context) async {
    if (StringUtil.isNotBlank(settingProvider.nwcUrl)) {
      textEditingController.text = settingProvider.nwcUrl!;
    }
  }

  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);
    var s = S.of(context);
    var mainColor = themeData.primaryColor;
    var cardColor = themeData.cardColor;

    List<Widget> list = [];

    list.add(Container(
      child: TextField(
        minLines: 4,
        maxLines: 4,
        autofocus: true,
        controller: textEditingController,
        decoration: InputDecoration(
          hintText: s.PLease_input_NWC_URL,
          border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(top: Base.BASE_PADDING),
      child: Row(
        children: [
          Expanded(
            child: Container(),
          ),
          TableModeUtil.isTableMode()
              ? Container()
              : GestureDetector(
                  onTap: scanQrCode,
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: mainColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                    ),
                  ),
                ),
          Container(
            margin: EdgeInsets.only(left: Base.BASE_PADDING),
            child: GestureDetector(
              onTap: openGetalby,
              behavior: HitTestBehavior.translucent,
              child: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ColorsUtil.hexToColor("#ffdf6f"),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset("assets/imgs/alby_logo.png"),
              ),
            ),
          ),
        ],
      ),
    ));

    list.add(Container(
      margin: EdgeInsets.only(top: 30),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: _onConfirm,
          highlightColor: mainColor.withOpacity(0.2),
          child: Container(
            color: mainColor,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              s.Confirm,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ));

    list.add(Container(
      margin: EdgeInsets.only(top: Base.BASE_PADDING),
      padding: EdgeInsets.all(Base.BASE_PADDING),
      decoration: BoxDecoration(
        color: themeData.hintColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
          "1. ${s.NWC_TIP1}\n2. ${s.NWC_TIP2} 'nostr+walletconnect:b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4?relay=wss%3A%2F%2Frelay.damus.io&secret=71a8c14c1407c113601079c4302dab36460f0ccd0ad506f1f2dc73b5100e4f3c'"),
    ));

    return Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
        left: 20,
        right: 20,
      ),
      color: cardColor,
      child: Column(
        children: list,
      ),
    );
  }

  void _onConfirm() {
    var result = textEditingController.text;
    if (StringUtil.isNotBlank(result)) {
      var nwc = NWCInfo.loadFromUrl(result);
      if (nwc == null) {
        BotToast.showText(text: S.of(context).Input_parse_error);
        return;
      }

      settingProvider.nwcUrl = result;
    } else {
      // try to clean nwc setting
      settingProvider.nwcUrl = null;
    }

    nwcProvider.reload();
    RouterUtil.back(context);
  }

  Future<void> scanQrCode() async {
    var result = await RouterUtil.router(context, RouterPath.QRSCANNER);
    if (StringUtil.isNotBlank(result)) {
      var nwc = NWCInfo.loadFromUrl(result!);
      if (nwc == null) {
        BotToast.showText(text: S.of(context).Input_parse_error);
        return;
      }

      textEditingController.text = result;
    }
  }

  Future<void> openGetalby() async {
    FocusScope.of(context).unfocus();

    var link = "https://nwc.getalby.com/apps/new?c=Nostrmo";
    if (TableModeUtil.isTableMode()) {
      launchUrl(Uri.parse(link));
      return;
    } else {
      var result = await webViewProvider.openWithFuture(link);
      if (StringUtil.isNotBlank(result)) {
        var nwc = NWCInfo.loadFromUrl(result!);
        if (nwc == null) {
          BotToast.showText(text: S.of(context).Input_parse_error);
          return;
        }

        textEditingController.text = result;
      }
    }
  }
}
