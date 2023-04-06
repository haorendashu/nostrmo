import 'package:flutter/material.dart';

import '../consts/base.dart';
import '../consts/base_consts.dart';
import '../util/router_util.dart';

class EnumSelectorComponent extends StatelessWidget {
  final List<EnumObj> list;

  EnumSelectorComponent({required this.list});

  static Future<EnumObj?> show(BuildContext context, List<EnumObj> list) async {
    return await showDialog<EnumObj?>(
      context: context,
      builder: (_context) {
        return EnumSelectorComponent(list: list);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var maxHeight = MediaQuery.of(context).size.height;

    List<Widget> widgets = [];
    for (var i = 0; i < list.length; i++) {
      var enumObj = list[i];
      widgets.add(EnumSelectorItemComponent(
        enumObj: enumObj,
        isLast: i == list.length - 1,
      ));
    }

    Widget main = Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        color: cardColor,
      ),
      constraints: BoxConstraints(
        maxHeight: maxHeight * 0.8,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widgets,
        ),
      ),
    );

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
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}

class EnumSelectorItemComponent extends StatelessWidget {
  static const double HEIGHT = 44;

  final EnumObj enumObj;

  final bool isLast;

  EnumSelectorItemComponent({
    required this.enumObj,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var dividerColor = themeData.dividerColor;

    Widget main = Container(
      padding: EdgeInsets.only(
          left: Base.BASE_PADDING + 5, right: Base.BASE_PADDING + 5),
      child: Text(enumObj.name),
    );

    return GestureDetector(
      onTap: () {
        RouterUtil.back(context, enumObj);
      },
      child: Container(
        decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: dividerColor))),
        alignment: Alignment.center,
        height: HEIGHT,
        child: main,
      ),
    );
  }
}
