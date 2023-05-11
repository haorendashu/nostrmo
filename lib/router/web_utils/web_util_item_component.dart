import 'package:flutter/material.dart';
import 'package:nostrmo/component/webview_router.dart';

import '../../consts/base.dart';

class WebUtilItemComponent extends StatelessWidget {
  String link;

  String des;

  WebUtilItemComponent({required this.link, required this.des});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;

    var main = Container(
      width: double.maxFinite,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      padding: const EdgeInsets.all(
        Base.BASE_PADDING,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 3),
            child: Text(
              this.link,
              style: TextStyle(
                fontSize: largeTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            this.des,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hintColor,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        WebViewRouter.open(context, link);
      },
      behavior: HitTestBehavior.translucent,
      child: main,
    );
  }
}
