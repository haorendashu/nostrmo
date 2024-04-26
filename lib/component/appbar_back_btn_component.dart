import 'package:flutter/material.dart';

import '../util/router_util.dart';

class AppbarBackBtnComponent extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AppbarBackBtnComponent();
  }
}

class _AppbarBackBtnComponent extends State<AppbarBackBtnComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    return GestureDetector(
      onTap: () {
        RouterUtil.back(context);
      },
      child: Icon(
        Icons.arrow_back_ios,
        color: themeData.appBarTheme.titleTextStyle!.color,
      ),
    );
  }
}
