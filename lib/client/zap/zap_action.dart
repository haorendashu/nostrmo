import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/widgets.dart';

import '../../main.dart';
import '../../util/lightning_util.dart';
import '../../util/string_util.dart';
import 'zap.dart';

class ZapAction {
  static Future<void> handleZap(BuildContext context, int sats, String pubkey,
      {String? eventId}) async {
    var metadata = metadataProvider.getMetadata(pubkey);
    if (metadata == null) {
      BotToast.showText(text: "Metadata can not be found.");
      return;
    }

    var relays = relayProvider.relayAddrs;

    if (StringUtil.isNotBlank(metadata.lud16)) {
      var lnurl = Zap.getLnurlFromLud16(metadata.lud16!);
      if (StringUtil.isNotBlank(lnurl)) {
        var lnurl = Zap.getLnurlFromLud16(metadata.lud16!);
        if (StringUtil.isBlank(lnurl)) {
          BotToast.showText(text: "Gen lnurl error.");
          return;
        }
        var invoiceCode = await Zap.getInvoiceCode(
          lnurl: lnurl!,
          sats: sats,
          recipientPubkey: pubkey,
          targetNostr: nostr!,
          relays: relays,
          eventId: eventId,
        );

        if (StringUtil.isBlank(invoiceCode)) {
          BotToast.showText(text: "Gen invoiceCode error.");
          return;
        }

        await LightningUtil.goToPay(invoiceCode!);
      }
    }
  }
}
