import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/widgets.dart';

import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/lightning_util.dart';
import '../../util/string_util.dart';
import 'zap.dart';

class ZapAction {
  static Future<void> handleZap(BuildContext context, int sats, String pubkey,
      {String? eventId, String? pollOption, String? comment}) async {
    var s = S.of(context);
    var cancelFunc = BotToast.showLoading();
    try {
      var invoiceCode = await _doGenInvoiceCode(context, sats, pubkey,
          eventId: eventId, pollOption: pollOption, comment: comment);

      if (StringUtil.isBlank(invoiceCode)) {
        BotToast.showText(text: s.Gen_invoice_code_error);
        return;
      }

      await LightningUtil.goToPay(context, invoiceCode!);
    } finally {
      cancelFunc.call();
    }
  }

  static Future<String?> genInvoiceCode(
      BuildContext context, int sats, String pubkey,
      {String? eventId, String? pollOption, String? comment}) async {
    var cancelFunc = BotToast.showLoading();
    try {
      return await _doGenInvoiceCode(context, sats, pubkey,
          eventId: eventId, pollOption: pollOption, comment: comment);
    } finally {
      cancelFunc.call();
    }
  }

  static Future<String?> _doGenInvoiceCode(
      BuildContext context, int sats, String pubkey,
      {String? eventId, String? pollOption, String? comment}) async {
    var s = S.of(context);
    var metadata = metadataProvider.getMetadata(pubkey);
    if (metadata == null) {
      BotToast.showText(text: s.Metadata_can_not_be_found);
      return null;
    }

    var relays = relayProvider.relayAddrs;

    // lud06 like: LNURL1DP68GURN8GHJ7MRW9E6XJURN9UH8WETVDSKKKMN0WAHZ7MRWW4EXCUP0XPURJCEKXVERVDEJXCMKYDFHV43KX2HK8GT
    // lud16 like: pavol@rusnak.io
    // but some people set lud16 to lud06
    String? lnurl = metadata.lud06;
    String? lud16Link;

    if (StringUtil.isBlank(lnurl)) {
      if (StringUtil.isNotBlank(metadata.lud16)) {
        lnurl = Zap.getLnurlFromLud16(metadata.lud16!);
      }
    }
    if (StringUtil.isBlank(lnurl)) {
      BotToast.showText(text: "Lnurl ${s.not_found}");
      return null;
    }
    // check if user set wrong
    if (lnurl!.contains("@")) {
      lnurl = Zap.getLnurlFromLud16(metadata.lud16!);
    }

    if (StringUtil.isBlank(lud16Link)) {
      if (StringUtil.isNotBlank(metadata.lud16)) {
        lud16Link = Zap.getLud16LinkFromLud16(metadata.lud16!);
      }
    }
    if (StringUtil.isBlank(lud16Link)) {
      if (StringUtil.isNotBlank(metadata.lud06)) {
        lud16Link = Zap.decodeLud06Link(metadata.lud06!);
      }
    }

    return await Zap.getInvoiceCode(
      lnurl: lnurl!,
      lud16Link: lud16Link!,
      sats: sats,
      recipientPubkey: pubkey,
      targetNostr: nostr!,
      relays: relays,
      eventId: eventId,
      pollOption: pollOption,
      comment: comment,
    );
  }
}
