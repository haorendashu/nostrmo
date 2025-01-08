import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';

class TextInputDialogInnerComponent extends StatefulWidget {
  String title;

  String? hintText;

  String? value;

  String? des;

  bool Function(BuildContext, String)? valueCheck;

  TextInputDialogInnerComponent(
    this.title, {
    this.hintText,
    this.value,
    this.des,
    this.valueCheck,
  });

  @override
  State<StatefulWidget> createState() {
    return _TextInputDialogInnerComponent();
  }
}

class _TextInputDialogInnerComponent
    extends State<TextInputDialogInnerComponent> {
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
    var desFontSize = themeData.textTheme.bodySmall!.fontSize;

    List<Widget> list = [];

    list.add(Container(
      child: Text(
        widget.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: titleFontSize,
        ),
      ),
    ));

    if (StringUtil.isNotBlank(widget.des)) {
      list.add(Container(
        child: Text(
          widget.des!,
          style: TextStyle(
            fontSize: desFontSize,
          ),
        ),
      ));
    }

    list.add(Container(
      margin: EdgeInsets.only(top: Base.BASE_PADDING),
      child: TextField(
        controller: controller,
        minLines: 4,
        maxLines: 4,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    list.add(Container(
      margin: EdgeInsets.only(top: Base.BASE_PADDING),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: _onConfirm,
          highlightColor: mainColor.withOpacity(0.2),
          child: Container(
            color: mainColor,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              S.of(context).Confirm,
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

    return main;
  }

  void _onConfirm() {
    var value = controller.text;
    // if (StringUtil.isBlank(value)) {
    //   BotToast.showText(text: "Input can't be null");
    //   return;
    // }

    if (widget.valueCheck != null) {
      if (!widget.valueCheck!(context, value)) {
        return;
      }
    }
    return RouterUtil.back(context, value);
  }
}
