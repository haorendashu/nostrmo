import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:url_launcher/url_launcher.dart';

import '../component/lightning_qrcode_dialog.dart';

class CashuUtil {
  static Future<void> goTo(BuildContext context, String cashuStr) async {
    var link = 'cashu:' + cashuStr;
    if (PlatformUtil.isPC() || PlatformUtil.isWeb()) {
      await LightningQrcodeDialog.show(context, link, title: "");
    } else {
      var url = Uri.parse(link);
      launchUrl(url);
    }
  }
}
