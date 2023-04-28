import 'package:flutter/material.dart';

import '../../client/event.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import 'zap_event_main_component.dart';

class ZapEventListComponent extends StatefulWidget {
  Event event;

  bool jumpable;

  ZapEventListComponent({
    required this.event,
    this.jumpable = true,
  });

  @override
  State<StatefulWidget> createState() {
    return _ZapEventListComponent();
  }
}

class _ZapEventListComponent extends State<ZapEventListComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    var main = Container(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      child: ZapEventMainComponent(
        event: widget.event,
      ),
    );

    if (widget.jumpable) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: jumpToThread,
        child: main,
      );
    } else {
      return main;
    }
  }

  void jumpToThread() {
    RouterUtil.router(context, RouterPath.THREAD_DETAIL, widget.event);
  }
}
