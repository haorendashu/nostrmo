import 'package:flutter/material.dart';
import 'package:nostrmo/util/string_util.dart';

class ContentStrLinkComponent extends StatelessWidget {
  String str;

  Function onTap;

  ContentStrLinkComponent({required this.str, required this.onTap});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    return GestureDetector(
      onTap: () {
        this.onTap();
      },
      child: Container(
        margin: EdgeInsets.only(right: 3),
        child: Text(
          StringUtil.breakWord(str),
          style: TextStyle(
            color: mainColor,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
