import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostr_sdk/zap/zap.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/nwc_provider.dart';
import 'package:nostrmo/router/nwc/nwc_setting_body_component.dart';
import 'package:nostrmo/util/zap_action.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../generated/l10n.dart';

class WalletRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _WalletRouter();
  }
}

class _WalletRouter extends State<WalletRouter> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var nwcProvider = Provider.of<NWCProvider>(context);

    var s = S.of(context);
    var themeData = Theme.of(context);
    var iconFontSize = themeData.textTheme.bodySmall!.fontSize! + 2;
    var smallFontSize = themeData.textTheme.bodySmall!.fontSize;
    var mainColor = themeData.primaryColor;

    if (!nwcProvider.isConnected()) {
      return Scaffold(
        appBar: AppBar(
          leading: AppbarBackBtnComponent(),
          title: Text(s.Wallet),
        ),
        body: NwcSettingBodyComponent(),
      );
    }

    List<Widget> list = [];

    var walletText = nwcProvider.lud16();
    if (StringUtil.isNotBlank(walletText)) {
      list.add(Positioned(
        top: 30,
        child: GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: walletText!));
            BotToast.showText(text: s.Copy_success);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(walletText!),
              Container(
                margin: const EdgeInsets.only(
                  left: Base.BASE_PADDING_HALF,
                ),
                child: Icon(
                  Icons.copy,
                  size: iconFontSize,
                ),
              ),
            ],
          ),
        ),
      ));
    }

    var balance = nwcProvider.balance;
    list.add(Container(
      padding: EdgeInsets.only(bottom: 100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.Balance),
              Container(
                margin: EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                child: Icon(
                  Icons.wallet,
                  size: iconFontSize,
                  color: Base.BTC_COLOR,
                ),
              ),
            ],
          ),
          Container(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  NumberFormat.decimalPattern().format(balance),
                  style: TextStyle(
                    fontSize: 32,
                    color: Base.BTC_COLOR,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  " sats",
                  style: TextStyle(
                    fontSize: 22,
                    color: Base.BTC_COLOR,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    ));

    list.add(Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(
              bottom: 20,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.arrow_upward,
                  size: smallFontSize,
                ),
                Text(
                  s.Last_Transactions,
                  style: TextStyle(
                    fontSize: smallFontSize,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 10,
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_downward,
                          color: Base.BTC_COLOR,
                        ),
                        Text(
                          s.Receive,
                          style: TextStyle(
                            color: Base.BTC_COLOR,
                          ),
                        ),
                      ],
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Base.BTC_COLOR,
                        width: 2.0,
                      ),
                      padding: const EdgeInsets.only(
                        top: 16,
                        bottom: 16,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 26,
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_upward),
                        Text(s.Send),
                      ],
                    ),
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.only(
                          top: 16,
                          bottom: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          s.Wallet,
          style: TextStyle(
            fontSize: themeData.textTheme.bodyLarge!.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: list,
        ),
      ),
    );
  }

  void receive() {
    var lud16 = nwcProvider.lud16();
    if (StringUtil.isBlank(lud16)) {
      return;
    }

    var cancelFunc = BotToast.showLoading();
    try {
      var lnurl = Zap.getLnurlFromLud16(lud16!);
    } finally {
      cancelFunc.call();
    }
  }
}
