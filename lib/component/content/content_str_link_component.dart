import 'package:flutter/material.dart';
import 'package:nostrmo/util/string_util.dart';

class ContentStrLinkComponent extends StatelessWidget {
  bool showUnderline;

  String str;

  Function onTap;

  ContentStrLinkComponent(
      {super.key,
      required this.str,
      required this.onTap,
      this.showUnderline = true});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;

    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Text(
        StringUtil.breakWord(str),
        style: TextStyle(
          color: mainColor,
          decoration:
              showUnderline ? TextDecoration.underline : TextDecoration.none,
          decorationColor: mainColor,
          fontSize: fontSize,
        ),
        // fix when flutter upgrade, text not vertical align by bottom
        strutStyle: StrutStyle(
          forceStrutHeight: true,
          fontSize: fontSize! + 2,
        ),
      ),
    );
  }
}
