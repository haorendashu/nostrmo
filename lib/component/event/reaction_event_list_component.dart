import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import 'reaction_event_item_component.dart';

class ReactionListEventComponent extends StatefulWidget {
  Event event;

  bool jumpable;

  String text;

  ReactionListEventComponent({
    required this.event,
    this.jumpable = true,
    required this.text,
  });

  @override
  State<StatefulWidget> createState() => _ReactionListEventComponent();
}

class _ReactionListEventComponent extends State<ReactionListEventComponent> {
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
      child: ReactionEventItemComponent(
        pubkey: widget.event.pubkey,
        text: widget.text,
        createdAt: widget.event.createdAt,
      ),
    );

    if (widget.jumpable) {
      return GestureDetector(
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
