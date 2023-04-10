import 'package:flutter/material.dart';

import '../../consts/base.dart';

class SearchActionItemComponent extends StatelessWidget {
  String title;

  Function onTap;

  SearchActionItemComponent({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var fontSize = themeData.textTheme.bodyLarge!.fontSize;
    var hintColor = themeData.hintColor;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        onTap();
      },
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING * 2,
          right: Base.BASE_PADDING * 2,
          top: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING,
        ),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
          width: 1,
          color: hintColor,
        ))),
        child: Text(
          title,
          style: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }
}
