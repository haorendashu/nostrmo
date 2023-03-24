import 'package:flutter/material.dart';

import '../../client/zap_num_util.dart';
import '../../consts/base.dart';

class ContnetLnbcComponent extends StatelessWidget {
  String lnbc;

  ContnetLnbcComponent({required this.lnbc});

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
      margin: EdgeInsets.all(Base.BASE_PADDING),
      padding: EdgeInsets.all(Base.BASE_PADDING * 2),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: Offset(0, 0),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            alignment: Alignment.topLeft,
            padding: EdgeInsets.only(bottom: Base.BASE_PADDING),
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
                  child: Icon(
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
            margin: EdgeInsets.only(
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
              onTap: () {
                // TODO call to pay
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
