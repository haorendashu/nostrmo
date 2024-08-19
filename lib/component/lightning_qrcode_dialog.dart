import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../util/router_util.dart';
import '../util/theme_util.dart';

class LightningQrcodeDialog extends StatefulWidget {
  String? title;

  String text;

  LightningQrcodeDialog({
    this.title,
    required this.text,
  });

  static Future<bool?> show(BuildContext context, String text,
      {String? content, String? title}) async {
    return await showDialog<bool>(
      context: context,
      builder: (_context) {
        return LightningQrcodeDialog(
          text: text,
          title: title,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _LightningQrcodeDialog();
  }
}

class _LightningQrcodeDialog extends State<LightningQrcodeDialog> {
  static const double IMAGE_WIDTH = 40;
  static const double QR_WIDTH = 200;

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    List<Widget> list = [];
    if (widget.title == null) {
      list.add(Container(
        child: Text(s.Use_lightning_wallet_scan_and_send_sats),
      ));
    } else {
      if (StringUtil.isNotBlank(widget.title)) {
        list.add(Container(
          child: Text(s.Use_lightning_wallet_scan_and_send_sats),
        ));
      }
    }
    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
        left: Base.BASE_PADDING_HALF,
        right: Base.BASE_PADDING_HALF,
      ),
      child: PrettyQr(
        data: widget.text,
        size: QR_WIDTH,
      ),
    ));
    list.add(GestureDetector(
      onTap: () {
        _doCopy(widget.text);
      },
      child: Container(
        padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
        margin: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: Base.BASE_PADDING_HALF,
        ),
        decoration: BoxDecoration(
          color: hintColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SelectableText(
          widget.text,
          onTap: () {
            _doCopy(widget.text);
          },
        ),
      ),
    ));

    var main = Container(
      width: QR_WIDTH + 200,
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );

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
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }

  void _doCopy(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      BotToast.showText(text: S.of(context).Copy_success);
    });
  }
}
