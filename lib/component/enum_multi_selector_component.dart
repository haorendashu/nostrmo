import 'package:flutter/material.dart';
import 'package:nostrmo/component/enum_selector_component.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/router_util.dart';

import '../consts/base_consts.dart';

class EnumMultiSelectorComponent extends StatefulWidget {
  final List<EnumObj> list;

  final List<EnumObj> values;

  EnumMultiSelectorComponent({
    required this.list,
    required this.values,
  });

  static Future<List<EnumObj>?> show(
      BuildContext context, List<EnumObj> list, List<EnumObj> values) async {
    return await showDialog<List<EnumObj>?>(
      context: context,
      useRootNavigator: false,
      builder: (_context) {
        return EnumMultiSelectorComponent(
          list: list,
          values: values,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _EnumMultiSelectorComponent();
  }
}

class _EnumMultiSelectorComponent extends State<EnumMultiSelectorComponent> {
  double BTN_WIDTH = 50;

  late List<EnumObj> values;

  @override
  void initState() {
    super.initState();
    values = widget.values;
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var btnTextColor = themeData.appBarTheme.titleTextStyle!.color;

    return Stack(
      alignment: Alignment.center,
      children: [
        EnumSelectorComponent(list: widget.list, enumItemBuild: enumItemBuild),
        Positioned(
          bottom: mediaDataCache.size.height / 20,
          child: GestureDetector(
            onTap: () {
              return RouterUtil.back(context, values);
            },
            child: Container(
              width: BTN_WIDTH,
              height: BTN_WIDTH,
              decoration: BoxDecoration(
                color: mainColor,
                borderRadius: BorderRadius.circular(BTN_WIDTH / 2),
              ),
              child: Icon(
                Icons.done,
                color: btnTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget enumItemBuild(BuildContext context, EnumObj enumObj) {
    bool isLast = false;
    if (enumObj.value == widget.list.last.value) {
      isLast = true;
    }

    bool exist = false;
    for (var value in values) {
      if (value.value == enumObj.value) {
        exist = true;
      }
    }

    return EnumSelectorItemComponent(
      enumObj: enumObj,
      isLast: isLast,
      onTap: onTap,
      color: exist ? Colors.blue.withOpacity(0.2) : null,
    );
  }

  void onTap(EnumObj enumObj) {
    bool exist = false;
    for (var value in values) {
      if (value.value == enumObj.value) {
        exist = true;
      }
    }

    if (exist) {
      values.removeWhere((element) {
        return element.value == enumObj.value;
      });
    } else {
      values.add(enumObj);
    }

    setState(() {});
  }
}
