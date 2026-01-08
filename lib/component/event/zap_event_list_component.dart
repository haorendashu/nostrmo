import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import 'zap_event_main_component.dart';

class ZapListEventComponent extends StatefulWidget {
  Event event;

  bool jumpable;

  ZapListEventComponent({
    required this.event,
    this.jumpable = true,
  });

  @override
  State<StatefulWidget> createState() {
    return _ZapListEventComponent();
  }
}

class _ZapListEventComponent extends State<ZapListEventComponent> {
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
    RouterUtil.router(context, RouterPath.getThreadDetailPath(), widget.event);
  }
}
