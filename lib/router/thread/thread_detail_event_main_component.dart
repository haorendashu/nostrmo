import 'package:flutter/material.dart';
import 'package:nostrmo/component/event/event_main_component.dart';
import 'package:nostrmo/router/thread/thread_detail_event.dart';
import 'package:screenshot/screenshot.dart';

import '../../consts/base.dart';

class ThreadDetailItemMainComponent extends StatefulWidget {
  ThreadDetailEvent item;

  ThreadDetailItemMainComponent({required this.item});

  @override
  State<StatefulWidget> createState() {
    return _ThreadDetailItemMainComponent();
  }
}

class _ThreadDetailItemMainComponent
    extends State<ThreadDetailItemMainComponent> {
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var cardColor = themeData.cardColor;

    List<Widget> list = [
      EventMainComponent(
        screenshotController: screenshotController,
        event: widget.item.event,
        showReplying: false,
        showVideo: true,
        imageListMode: false,
      )
    ];

    if (widget.item.subItems != null && widget.item.subItems.isNotEmpty) {
      List<Widget> subWidgets = [];
      for (var subItem in widget.item.subItems) {
        subWidgets.add(
          Container(
            child: ThreadDetailItemMainComponent(
              item: subItem,
            ),
          ),
        );
      }
      list.add(Container(
        margin: const EdgeInsets.only(
          // top: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING,
          left: Base.BASE_PADDING,
        ),
        decoration: BoxDecoration(
            border: Border(
                left: BorderSide(
          width: 2,
          color: hintColor,
        ))),
        child: Column(children: subWidgets),
      ));
    }

    return Screenshot(
      child: Container(
        padding: EdgeInsets.only(
          top: Base.BASE_PADDING,
        ),
        color: cardColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: list,
        ),
      ),
      controller: screenshotController,
    );
  }
}
