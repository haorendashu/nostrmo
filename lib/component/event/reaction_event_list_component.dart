import 'package:flutter/material.dart';

import '../../client/event.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import 'reaction_event_item_component.dart';

class ReactionEventListComponent extends StatefulWidget {
  Event event;

  bool jumpable;

  String text;

  ReactionEventListComponent({
    required this.event,
    this.jumpable = true,
    required this.text,
  });

  @override
  State<StatefulWidget> createState() => _ReactionEventListComponent();
}

class _ReactionEventListComponent extends State<ReactionEventListComponent> {
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
        pubkey: widget.event.pubKey,
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
    RouterUtil.router(context, RouterPath.THREAD_DETAIL, widget.event);
  }
}
