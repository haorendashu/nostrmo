import 'package:flutter/material.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';
import 'text_input_dialog_inner_component.dart';

class TextInputDialog extends StatefulWidget {
  String title;

  String? hintText;

  String? value;

  bool Function(BuildContext, String)? valueCheck;

  TextInputDialog(
    this.title, {
    this.hintText,
    this.value,
    this.valueCheck,
  });

  @override
  State<StatefulWidget> createState() {
    return _TextInputDialog();
  }

  static Future<String?> show(BuildContext context, String title,
      {String? value,
      String? hintText,
      bool Function(BuildContext, String)? valueCheck}) async {
    return await showDialog<String>(
        context: context,
        builder: (_context) {
          return TextInputDialog(
            StringUtil.breakWord(title),
            hintText: hintText,
            value: value,
            valueCheck: valueCheck,
          );
        });
  }
}

class _TextInputDialog extends State<TextInputDialog> {
  @override
  Widget build(BuildContext context) {
    var main = TextInputDialogInnerComponent(
      widget.title,
      hintText: widget.hintText,
      value: widget.value,
      valueCheck: widget.valueCheck,
    );

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        autofocus: true,
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
