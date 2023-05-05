import 'package:flutter/material.dart';

import '../../consts/base.dart';

class SettingGroupTitleComponent extends StatelessWidget {
  IconData iconData;

  String title;

  SettingGroupTitleComponent({
    required this.iconData,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.only(
          top: 30,
        ),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(right: Base.BASE_PADDING_HALF),
              child: Icon(
                iconData,
                color: hintColor,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: hintColor,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
