import 'package:flutter/material.dart';
import 'package:nostrmo/component/event/event_main_component.dart';
import 'package:nostrmo/router/thread/thread_detail_event.dart';

import '../../consts/base.dart';
import 'thread_detail_event_main_component.dart';

class ThreadDetailItemComponent extends StatefulWidget {
  ThreadDetailEvent item;

  ThreadDetailItemComponent({required this.item});

  @override
  State<StatefulWidget> createState() {
    return _ThreadDetailItemComponent();
  }
}

class _ThreadDetailItemComponent extends State<ThreadDetailItemComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    return Container(
      color: cardColor,
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      padding: EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      child: ThreadDetailItemMainComponent(item: widget.item),
    );
  }
}
