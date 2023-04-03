import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

class LightningUtil {
  static Future<void> goToPay(String invoiceCode) async {
    var link = 'lightning:' + invoiceCode;
    if (Platform.isAndroid) {
      AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: link,
      );
      await intent.launch();
    } else {
      var url = Uri.parse(link);
      launchUrl(url);
    }
  }
}
