import 'package:flutter/material.dart';

import '../../client/event_kind.dart' as kind;
import '../../component/event/event_bitcion_icon_component.dart';
import '../../consts/base.dart';
import 'thread_detail_event.dart';
import 'thread_detail_event_main_component.dart';

class ThreadDetailItemComponent extends StatefulWidget {
  double totalMaxWidth;

  ThreadDetailEvent item;

  String sourceEventId;

  GlobalKey sourceEventKey;

  ThreadDetailItemComponent({
    required this.item,
    required this.totalMaxWidth,
    required this.sourceEventId,
    required this.sourceEventKey,
  });

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

    Widget main = ThreadDetailItemMainComponent(
      item: widget.item,
      totalMaxWidth: widget.totalMaxWidth,
      sourceEventId: widget.sourceEventId,
      sourceEventKey: widget.sourceEventKey,
    );

    if (widget.item.event.kind == kind.EventKind.ZAP) {
      main = Stack(
        children: [
          main,
          Positioned(
            top: -35,
            right: -10,
            child: EventBitcionIconComponent(),
          ),
        ],
      );
    }

    return Container(
      color: cardColor,
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: main,
    );
  }
}
