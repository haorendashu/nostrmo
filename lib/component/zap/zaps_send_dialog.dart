import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:nostrmo/client/zap/zap_action.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/user/name_component.dart';
import 'package:nostrmo/component/user/user_pic_component.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';

import '../../client/event_relation.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/lightning_util.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';
import '../user/metadata_top_component.dart';

class ZapsSendDialog extends StatefulWidget {
  Map<String, int> pubkeyZapNumbers;

  List<EventZapInfo> zapInfos;

  String? comment;

  ZapsSendDialog({
    required this.zapInfos,
    required this.pubkeyZapNumbers,
    this.comment,
  });

  @override
  State<StatefulWidget> createState() {
    return _ZapsSendDialog();
  }
}

class _ZapsSendDialog extends CustState<ZapsSendDialog> {
  Map<String, String> invoicesMap = {};

  Map<String, bool> sendedMap = {};

  @override
  Widget doBuild(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];
    for (var zapInfo in widget.zapInfos) {
      var pubkey = zapInfo.pubkey;
      var invoiceCode = invoicesMap[pubkey];
      var sended = sendedMap[pubkey];
      var zapNumber = widget.pubkeyZapNumbers[pubkey];
      if (zapNumber == null) {
        continue;
      }

      list.add(Container(
        margin: EdgeInsets.only(
          top: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: ZapsSendDialogItem(
          pubkey,
          zapNumber,
          sendZapFunction,
          invoiceCode: invoiceCode,
          sended: sended,
        ),
      ));
    }

    var main = Container(
      padding: EdgeInsets.all(Base.BASE_PADDING),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            // height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    invoicesMap.clear();
    sendedMap.clear();

    for (var zapInfo in widget.zapInfos) {
      var pubkey = zapInfo.pubkey;
      var zapNum = widget.pubkeyZapNumbers[pubkey];
      if (zapNum == null) {
        continue;
      }

      var invoiceCode = await ZapAction.genInvoiceCode(context, zapNum, pubkey);
      if (StringUtil.isNotBlank(invoiceCode)) {
        setState(() {
          invoicesMap[pubkey] = invoiceCode!;
        });
      }
    }
  }

  void sendZapFunction(String pubkey, String invoiceCode, int zapNum) {
    LightningUtil.goToPay(context, invoiceCode, zapNum: zapNum);
    setState(() {
      sendedMap[pubkey] = true;
    });
  }
}

class ZapsSendDialogItem extends StatelessWidget {
  double height = 50;

  double rightHeight = 40;

  double rightWidth = 80;

  String pubkey;

  int zapNumber;

  String? invoiceCode;

  bool? sended;

  Function(String, String, int) sendZapFunction;

  ZapsSendDialogItem(this.pubkey, this.zapNumber, this.sendZapFunction,
      {this.invoiceCode, this.sended});

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    return Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
      var userPicComp = UserPicComponent(pubkey: pubkey, width: height);

      var nameColum = Container(
        margin: const EdgeInsets.only(
          left: Base.BASE_PADDING,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NameComponent(
              pubkey: pubkey,
              metadata: metadata,
            ),
            Text(
              "$zapNumber Sats",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      );

      Widget rightComp = Container(
        height: rightHeight,
        width: rightWidth,
        child: const Icon(
          Icons.done,
          color: Colors.green,
        ),
      );
      if (sended != true && invoiceCode != null) {
        rightComp = GestureDetector(
          child: Container(
            height: rightHeight,
            width: rightWidth,
            child: MetadataTextBtn(
              text: s.Send,
              onTap: () {
                sendZapFunction(pubkey, invoiceCode!, zapNumber);
              },
            ),
          ),
        );
      } else if (invoiceCode == null) {
        rightComp = Container(
          height: rightHeight,
          width: rightWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: rightHeight,
                height: rightHeight,
                child: CircularProgressIndicator(),
              ),
            ],
          ),
        );
      }

      return Container(
        child: Row(
          children: [
            userPicComp,
            nameColum,
            Expanded(child: Container()),
            rightComp,
          ],
        ),
      );
    }, selector: (context, provider) {
      return provider.getMetadata(pubkey);
    });
  }
}
