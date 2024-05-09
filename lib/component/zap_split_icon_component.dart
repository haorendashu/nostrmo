import 'package:flutter/material.dart';

class ZapSplitIconComponent extends StatelessWidget {
  double fontSize;

  Color? color;

  ZapSplitIconComponent(this.fontSize, {this.color = Colors.orange});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    if (color == null) {
      color = themeData.iconTheme.color;
    }

    List<Widget> list = [];
    list.add(Positioned(
      left: 0,
      child: Icon(
        Icons.bolt,
        size: fontSize + 2,
        color: color,
      ),
    ));
    list.add(Positioned(
      right: 2,
      top: 1,
      child: Text(
        ">",
        style: TextStyle(
          fontSize: fontSize - 2,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ));

    return Container(
      width: fontSize + 8,
      height: fontSize + 8,
      child: Stack(
        alignment: Alignment.center,
        children: list,
      ),
    );
  }
}
