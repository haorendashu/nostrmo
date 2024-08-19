import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostrmo/component/lightning_qrcode_dialog.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/number_format_util.dart';
import 'package:url_launcher/url_launcher.dart';

import '../generated/l10n.dart';

class LightningUtil {
  static Future<void> goToPay(BuildContext context, String invoiceCode,
      {int? zapNum}) async {
    if (nwcProvider.isConnected()) {
      var s = S.of(context);
      var themeData = Theme.of(context);
      var fontSize = themeData.textTheme.bodyMedium!.fontSize;

      var text = "Zap";
      if (zapNum != null) {
        text = "${NumberFormatUtil.format(zapNum)} Sats";
      }

      bool send = true;
      BotToast.showNotification(
        duration: const Duration(seconds: 5),
        onlyOne: false,
        leading: (cancelFunc) {
          return CircularProgressIndicator();
        },
        title: (cancelFunc) {
          return Row(
            children: [
              Icon(
                Icons.bolt,
                color: Colors.orange,
              ),
              Text(
                "$text ${s.is_sending}...",
                style: TextStyle(
                  fontSize: fontSize,
                ),
              ),
            ],
          );
        },
        trailing: (cancelFunc) {
          return FilledButton(
            child: Text(
              s.Cancel,
              style: TextStyle(
                fontSize: fontSize,
              ),
            ),
            onPressed: () {
              send = false;
              cancelFunc.call();
            },
          );
        },
        onClose: () {
          // print("sendZap $send $invoiceCode");
          if (send) {
            nwcProvider.sendZap(context, invoiceCode);
          } else {
            log("Zap has bean cancel.");
          }
        },
      );
      return;
    }

    var link = 'lightning:' + invoiceCode;
    if (PlatformUtil.isPC() || PlatformUtil.isWeb()) {
      await LightningQrcodeDialog.show(context, link);
    } else {
      // if (Platform.isAndroid) {
      //   AndroidIntent intent = AndroidIntent(
      //     action: 'action_view',
      //     data: link,
      //   );
      //   await intent.launch();
      // } else {
      var url = Uri.parse(link);
      launchUrl(url);
      // }
    }
  }
}
