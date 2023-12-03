import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/component/lightning_qrcode_dialog.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:url_launcher/url_launcher.dart';

class LightningUtil {
  static Future<void> goToPay(BuildContext context, String invoiceCode) async {
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
