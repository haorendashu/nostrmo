import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/util/string_util.dart';

import '../../consts/base.dart';
import '../../util/router_util.dart';

class TextInputDialog extends StatefulWidget {
  String title;

  String? value;

  bool Function(BuildContext, String)? valueCheck;

  TextInputDialog(
    this.title, {
    this.value,
    this.valueCheck,
  });

  @override
  State<StatefulWidget> createState() {
    return _TextInputDialog();
  }

  static Future<String?> show(BuildContext context, String title,
      {String? value, bool Function(BuildContext, String)? valueCheck}) async {
    return await showDialog<String>(
        context: context,
        builder: (_context) {
          return TextInputDialog(
            title,
            value: value,
            valueCheck: valueCheck,
          );
        });
  }
}

class _TextInputDialog extends State<TextInputDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.value);
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];

    list.add(Container(
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING),
      child: Text(
        widget.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: titleFontSize,
        ),
      ),
    ));

    list.add(Container(
      child: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 10,
        autofocus: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    list.add(Container(
      margin: EdgeInsets.only(top: Base.BASE_PADDING),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: _onComfirm,
          highlightColor: mainColor.withOpacity(0.2),
          child: Container(
            color: mainColor,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              "Comfirm",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ));

    var main = Container(
      padding: EdgeInsets.all(Base.BASE_PADDING),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: list,
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

  void _onComfirm() {
    var value = controller.text;
    if (StringUtil.isBlank(value)) {
      BotToast.showText(text: "Input can't be null");
      return;
    }

    if (widget.valueCheck != null) {
      if (!widget.valueCheck!(context, value)) {
        return;
      }
    }
    return RouterUtil.back(context, value);
  }
}
