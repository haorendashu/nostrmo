import 'package:flutter/material.dart';

import '../consts/base.dart';
import '../consts/router_path.dart';
import '../util/router_util.dart';

class TagComponent extends StatelessWidget {
  final String tag;

  bool jumpable;

  TagComponent({
    required this.tag,
    this.jumpable = true,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;

    var main = Container(
      padding: EdgeInsets.only(
        left: Base.BASE_PADDING_HALF,
        right: Base.BASE_PADDING_HALF,
        top: 4,
        bottom: 4,
      ),
      decoration: BoxDecoration(
        color: mainColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );

    if (!jumpable) {
      return main;
    }

    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.TAG_DETAIL, tag);
      },
      child: main,
    );
  }
}
