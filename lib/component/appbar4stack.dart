import 'package:flutter/material.dart';

import '../util/router_util.dart';

class Appbar4Stack extends StatefulWidget {
  Widget? title;

  Color? backgroundColor;

  Appbar4Stack({this.title, this.backgroundColor});

  @override
  State<StatefulWidget> createState() {
    return _Appbar4Stack();
  }
}

class _Appbar4Stack extends State<Appbar4Stack> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var backgroundColor = widget.backgroundColor;
    if (backgroundColor == null) {
      backgroundColor = themeData.appBarTheme.backgroundColor;
    }

    List<Widget> list = [
      GestureDetector(
        child: Container(
          alignment: Alignment.center,
          width: 40,
          child: Icon(Icons.arrow_back_ios_new),
        ),
        onTap: () {
          RouterUtil.back(context);
        },
      )
    ];

    if (widget.title != null) {
      list.add(Expanded(child: widget.title!));
    }

    list.add(Container(
      width: 40,
    ));

    return Container(
      height: 40,
      color: backgroundColor,
      child: Row(
        children: list,
      ),
    );
  }
}
