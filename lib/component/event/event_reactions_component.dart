import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/data/event_reactions.dart';
import 'package:nostrmo/provider/event_reactions_provider.dart';
import 'package:provider/provider.dart';

import '../../data/metadata.dart';

class EventReactionsComponent extends StatefulWidget {
  Event event;

  EventReactionsComponent({required this.event});

  @override
  State<StatefulWidget> createState() {
    return _EventReactionsComponent();
  }
}

class _EventReactionsComponent extends State<EventReactionsComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var fontSize = themeData.textTheme.bodySmall!.fontSize!;

    return Selector<EventReactionsProvider, EventReactions?>(
      builder: (context, eventReactions, child) {
        int replyNum = 0;
        int repostNum = 0;
        int likeNum = 0;
        int zapNum = 0;

        if (eventReactions != null) {
          replyNum = eventReactions.replies.length;
          repostNum = eventReactions.repostNum;
          likeNum = eventReactions.likeNum;
          zapNum = eventReactions.zapNum;
        }

        return Container(
          height: 34,
          child: Row(
            children: [
              Expanded(
                  child: EventReactionNumComponent(
                num: replyNum,
                iconData: Icons.comment,
                onTap: onCommmentTap,
                color: hintColor,
                fontSize: fontSize,
              )),
              Expanded(
                  child: EventReactionNumComponent(
                num: repostNum,
                iconData: Icons.repeat,
                onTap: onCommmentTap,
                color: hintColor,
                fontSize: fontSize,
              )),
              Expanded(
                  child: EventReactionNumComponent(
                num: likeNum,
                iconData: Icons.favorite,
                onTap: onCommmentTap,
                color: hintColor,
                fontSize: fontSize,
              )),
              Expanded(
                  child: EventReactionNumComponent(
                num: zapNum,
                iconData: Icons.bolt,
                onTap: onZapTap,
                color: hintColor,
                fontSize: fontSize,
              )),
              Expanded(
                  child: EventReactionNumComponent(
                num: 0,
                iconData: Icons.share,
                onTap: onCommmentTap,
                color: hintColor,
                fontSize: fontSize,
              )),
            ],
          ),
        );
      },
      selector: (context, _provider) {
        return _provider.get(widget.event.id);
      },
      shouldRebuild: (previous, next) {
        if (previous != next ||
            (previous != null &&
                next != null &&
                (previous.replies.length != next.replies.length ||
                    previous.repostNum != next.repostNum ||
                    previous.likeNum != next.likeNum ||
                    previous.zapNum != next.zapNum))) {
          return true;
        }

        return false;
      },
    );
  }

  void onCommmentTap() {}

  void onRepostTap() {}

  void onLikeTap() {}

  void onZapTap() {}

  void onShareTap() {}
}

class EventReactionNumComponent extends StatelessWidget {
  IconData iconData;

  int num;

  Function onTap;

  Color color;

  double fontSize;

  EventReactionNumComponent({
    required this.iconData,
    required this.num,
    required this.onTap,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    Widget? main;
    var iconWidget = Icon(
      iconData,
      size: 14,
      color: color,
    );
    if (num != 0) {
      main = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconWidget,
          Container(
            margin: EdgeInsets.only(left: 4),
            child: Text(
              num.toString(),
              style: TextStyle(color: color, fontSize: fontSize),
            ),
          ),
        ],
      );
    } else {
      main = iconWidget;
    }

    return IconButton(
      onPressed: () {
        onTap();
      },
      icon: main,
    );
  }
}
