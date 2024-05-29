import 'package:flutter/material.dart';

class MainBtnComponent extends StatelessWidget {
  String text;

  Function? onTap;

  MainBtnComponent({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;

    return Ink(
      decoration: BoxDecoration(color: mainColor),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          }
        },
        highlightColor: mainColor.withOpacity(0.2),
        child: Container(
          color: mainColor,
          height: 40,
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
