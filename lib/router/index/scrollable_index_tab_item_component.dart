import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:widget_size/widget_size.dart';

import 'index_app_bar.dart';

class ScrollableIndexTabItemComponent extends StatefulWidget {
  String text;

  TextStyle textStyle;

  ScrollableIndexTabItemComponent(this.text, this.textStyle);

  @override
  State<StatefulWidget> createState() {
    return _ScrollableIndexTabItemComponent();
  }
}

class _ScrollableIndexTabItemComponent
    extends State<ScrollableIndexTabItemComponent> {
  bool showFullText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: IndexAppBar.height - 3,
      alignment: Alignment.center,
      child: Text(
        widget.text,
        style: widget.textStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}
