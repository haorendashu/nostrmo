import 'package:flutter/material.dart';
import 'package:nostrmo/client/cashu/cashu_tokens.dart';
import 'package:nostrmo/util/colors_util.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/cashu_util.dart';

class ContentCashuComponent extends StatelessWidget {
  String cashuStr;

  Tokens tokens;

  ContentCashuComponent({
    required this.tokens,
    required this.cashuStr,
  });

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var cardColor = themeData.cardColor;
    double largeFontSize = 20;

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
            margin: EdgeInsets.only(
              bottom: 15,
            ),
            child: Row(
              children: [
                Container(
                  margin: EdgeInsets.only(right: Base.BASE_PADDING),
                  child: Image.asset(
                    "assets/imgs/cashu_logo.png",
                    width: 50,
                    height: 50,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Row(
                        children: [
                          Container(
                            margin:
                                EdgeInsets.only(right: Base.BASE_PADDING_HALF),
                            child: Text(
                              tokens.totalAmount().toString(),
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
                      margin: EdgeInsets.only(top: 4),
                      child: Text(
                        tokens.memo != null ? tokens.memo! : "",
                        style: TextStyle(color: hintColor),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          Container(
            width: double.maxFinite,
            child: InkWell(
              onTap: () async {
                // call to pay
                CashuUtil.goTo(context, cashuStr);
              },
              child: Container(
                color: ColorsUtil.hexToColor("#dcc099"),
                height: 42,
                alignment: Alignment.center,
                child: Text(
                  "Claim",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
