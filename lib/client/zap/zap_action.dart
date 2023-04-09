import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/widgets.dart';

import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/lightning_util.dart';
import '../../util/string_util.dart';
import 'zap.dart';

class ZapAction {
  static Future<void> handleZap(BuildContext context, int sats, String pubkey,
      {String? eventId}) async {
    var s = S.of(context);
    var cancelFunc = BotToast.showLoading();
    try {
      var metadata = metadataProvider.getMetadata(pubkey);
      if (metadata == null) {
        BotToast.showText(text: s.Metadata_can_not_be_found);
        return;
      }

      var relays = relayProvider.relayAddrs;

      String? lnurl = metadata.lud06;
      if (StringUtil.isBlank(lnurl)) {
        if (StringUtil.isNotBlank(metadata.lud16)) {
          lnurl = Zap.getLnurlFromLud16(metadata.lud16!);
        }
      }

      if (StringUtil.isBlank(lnurl)) {
        BotToast.showText(text: "Lnurl ${s.not_found}");
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
        BotToast.showText(text: s.Gen_invoice_code_error);
        return;
      }

      await LightningUtil.goToPay(invoiceCode!);
    } finally {
      cancelFunc.call();
    }
  }
}
