import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/data/event_reactions.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/event_reactions_provider.dart';
import 'package:nostrmo/router/edit/editor_router.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../client/event_relation.dart';
import '../../util/store_util.dart';

class EventReactionsComponent extends StatefulWidget {
  ScreenshotController screenshotController;

  Event event;

  EventRelation eventRelation;

  EventReactionsComponent({
    required this.screenshotController,
    required this.event,
    required this.eventRelation,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventReactionsComponent();
  }
}

class _EventReactionsComponent extends State<EventReactionsComponent> {
  List<Event>? myLikeEvents;

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
        Color likeColor = hintColor;

        if (eventReactions != null) {
          replyNum = eventReactions.replies.length;
          repostNum = eventReactions.repostNum;
          likeNum = eventReactions.likeNum;
          zapNum = eventReactions.zapNum;

          myLikeEvents = eventReactions.myLikeEvents;
        }
        if (myLikeEvents != null && myLikeEvents!.isNotEmpty) {
          likeColor = Colors.red;
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
                onTap: onRepostTap,
                color: hintColor,
                fontSize: fontSize,
              )),
              Expanded(
                  child: EventReactionNumComponent(
                num: likeNum,
                iconData: Icons.favorite,
                onTap: onLikeTap,
                color: likeColor,
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
                onTap: onShareTap,
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
        if ((previous == null && next != null) ||
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

  @override
  void dispose() {
    super.dispose();
    var id = widget.event.id;
    eventReactionsProvider.removePendding(id);
  }

  void onCommmentTap() {
    List<dynamic> tags = [];
    List<dynamic> tagsAddedWhenSend = [];
    tagsAddedWhenSend.add(["e", widget.event.id, "", "reply"]);

    var er = widget.eventRelation;
    tags.add(["p", widget.event.pubKey]);
    if (er.tagPList.isNotEmpty) {
      tags.add(er.tagPList);
    }
    if (StringUtil.isNotBlank(er.rootId)) {
      tags.add(["e", er.rootId, "", "root"]);
    }

    // TODO reply maybe change the placeholder in editor router.
    EditorRouter.open(context,
        tags: tags, tagsAddedWhenSend: tagsAddedWhenSend);
  }

  void onRepostTap() {
    nostr!.sendRepost(widget.event.id);
    eventReactionsProvider.addRepost(widget.event.id);
  }

  void onLikeTap() {
    if (myLikeEvents == null || myLikeEvents!.isEmpty) {
      // like
      nostr!.sendLike(widget.event.id);
      eventReactionsProvider.addLike(widget.event.id);
    } else {
      // delete like
      for (var event in myLikeEvents!) {
        nostr!.deleteLike(event.id);
        eventReactionsProvider.deleteLike(widget.event.id);
      }
    }
  }

  void onZapTap() {}

  void onShareTap() {
    widget.screenshotController.capture().then((Uint8List? imageData) async {
      if (imageData != null) {
        if (imageData != null) {
          var tempFile = await StoreUtil.saveBS2TempFile(
            "png",
            imageData,
          );
          Share.shareXFiles([XFile(tempFile)]);
        }
      }
    }).catchError((onError) {
      print(onError);
    });
  }
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
            margin: const EdgeInsets.only(left: 4),
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
