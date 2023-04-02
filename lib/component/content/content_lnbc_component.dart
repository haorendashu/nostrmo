import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../client/zap_num_util.dart';
import '../../consts/base.dart';

class ContentLnbcComponent extends StatelessWidget {
  String lnbc;

  ContentLnbcComponent({required this.lnbc});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var cardColor = themeData.cardColor;
    double largeFontSize = 20;

    var numStr = "Any";
    var num = ZapNumUtil.getNumFromStr(lnbc);
    if (num > 0) {
      numStr = num.toString();
    }

    return Container(
      margin: const EdgeInsets.all(Base.BASE_PADDING),
      padding: const EdgeInsets.all(Base.BASE_PADDING * 2),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 0),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(bottom: Base.BASE_PADDING),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 1,
                  color: hintColor,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.orange,
                  ),
                ),
                Text("Lightning Invoice"),
              ],
            ),
          ),
          Container(
            alignment: Alignment.bottomLeft,
            padding: EdgeInsets.only(top: Base.BASE_PADDING),
            child: Text("Wallet of Satoshi"),
          ),
          Container(
            margin: const EdgeInsets.only(
              top: Base.BASE_PADDING,
              bottom: Base.BASE_PADDING,
            ),
            child: Row(
              children: [
                Container(
                  margin: EdgeInsets.only(right: Base.BASE_PADDING_HALF),
                  child: Text(
                    numStr,
                    style: TextStyle(
                      fontSize: largeFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  "sats",
                  style: TextStyle(
                    fontSize: largeFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.maxFinite,
            child: InkWell(
              onTap: () async {
                // TODO call to pay
                print(lnbc);
                var link = 'lightning:' + lnbc;
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
              },
              child: Container(
                color: Colors.black,
                height: 50,
                alignment: Alignment.center,
                child: Text(
                  "Pay",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
