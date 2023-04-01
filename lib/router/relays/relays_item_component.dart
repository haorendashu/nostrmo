import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostrmo/main.dart';

import '../../consts/base.dart';
import '../../data/relay_status.dart';

class RelaysItemComponent extends StatelessWidget {
  String addr;

  RelayStatus relayStatus;

  RelaysItemComponent({required this.addr, required this.relayStatus});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    Color borderLeftColor = Colors.green;
    if (!relayStatus.connected) {
      borderLeftColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: Base.BASE_PADDING,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.only(
          top: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            left: BorderSide(
              width: 6,
              color: borderLeftColor,
            ),
          ),
          // borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 2),
                    child: Text(addr),
                  ),
                  Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: Base.BASE_PADDING),
                        child: RelaysItemNumComponent(
                          iconData: Icons.mail,
                          num: relayStatus.noteReceived,
                        ),
                      ),
                      Container(
                        child: RelaysItemNumComponent(
                          iconColor: Colors.red,
                          iconData: Icons.error,
                          num: relayStatus.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                removeRelay(addr);
              },
              child: Container(
                child: Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void removeRelay(String addr) {
    relayProvider.removeRelay(addr);
  }
}

class RelaysItemNumComponent extends StatelessWidget {
  Color? iconColor;

  IconData iconData;

  int num;

  RelaysItemNumComponent({
    this.iconColor,
    required this.iconData,
    required this.num,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var smallFontSize = themeData.textTheme.bodySmall!.fontSize;

    return Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(right: Base.BASE_PADDING_HALF),
            child: Icon(
              iconData,
              color: iconColor,
              size: smallFontSize,
            ),
          ),
          Text(
            num.toString(),
            style: TextStyle(
              fontSize: smallFontSize,
            ),
          ),
        ],
      ),
    );
  }
}
