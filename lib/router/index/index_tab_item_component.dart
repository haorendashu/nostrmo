import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:widget_size/widget_size.dart';

import 'index_app_bar.dart';

class IndexTabItemComponent extends StatefulWidget {
  String text;

  String? omitText;

  TextStyle textStyle;

  IndexTabItemComponent(
    this.text,
    this.textStyle, {
    this.omitText,
  });

  @override
  State<StatefulWidget> createState() {
    return _IndexTabItemComponent();
  }
}

class _IndexTabItemComponent extends State<IndexTabItemComponent> {
  bool showFullText = true;

  @override
  Widget build(BuildContext context) {
    return WidgetSize(
      onChange: (size) {
        log("size is ${size.width}");
        if (size.width < 50) {
          if (showFullText && StringUtil.isNotBlank(widget.omitText)) {
            setState(() {
              showFullText = false;
            });
          }
        } else {
          if (!showFullText) {
            setState(() {
              showFullText = true;
            });
          }
        }
      },
      child: Container(
        height: IndexAppBar.height,
        alignment: Alignment.center,
        child: Text(
          showFullText ? widget.text : widget.omitText!,
          style: widget.textStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
