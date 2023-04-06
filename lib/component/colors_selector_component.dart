import 'package:flutter/material.dart';

import '../consts/base.dart';
import '../consts/colors.dart';
import '../util/router_util.dart';

class ColorSelectorComponent extends StatelessWidget {
  ColorSelectorComponent();

  static Future<Color?> show(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (_context) {
        return ColorSelectorComponent();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    List<Widget> widgets = [];
    for (var i = 0; i < ColorList.ALL_COLOR.length; i++) {
      var c = ColorList.ALL_COLOR[i];
      widgets.add(SliverToBoxAdapter(
        child: ColorSelectorItemComponent(
          color: c,
          // isLast: i == ColorList.ALL_COLOR.length - 1,
        ),
      ));
    }

    Widget main = Container(
        width: double.infinity,
        height: 100,
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
          top: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
        ),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          color: Colors.white,
        ),
        child: CustomScrollView(
          scrollDirection: Axis.horizontal,
          slivers: widgets,
        ));

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }
}

class ColorSelectorItemComponent extends StatelessWidget {
  static const double HEIGHT = 44;

  final Color color;

  // final bool isLast;

  ColorSelectorItemComponent({
    required this.color,
    // this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var dividerColor = themeData.dividerColor;

    return GestureDetector(
      onTap: () {
        RouterUtil.back(context, color);
      },
      child: Container(
        // decoration: BoxDecoration(
        //     border: isLast
        //         ? null
        //         : Border(bottom: BorderSide(color: dividerColor))),
        margin: EdgeInsets.all(Base.BASE_PADDING),
        alignment: Alignment.center,
        height: HEIGHT,
        child: Container(
          height: HEIGHT,
          width: HEIGHT,
          color: color,
        ),
      ),
    );
  }
}
