import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:screenshot/screenshot.dart';

import '../../client/event_kind.dart' as kind;
import '../../client/event.dart';
import '../../client/event_relation.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import 'event_bitcion_icon_component.dart';
import 'event_main_component.dart';

class EventListComponent extends StatefulWidget {
  Event event;

  String? pagePubkey;

  bool jumpable;

  bool showVideo;

  bool imageListMode;

  bool showDetailBtn;

  bool showLongContent;

  EventListComponent({
    required this.event,
    this.pagePubkey,
    this.jumpable = true,
    this.showVideo = false,
    this.imageListMode = true,
    this.showDetailBtn = true,
    this.showLongContent = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventListComponent();
  }
}

class _EventListComponent extends State<EventListComponent> {
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    Widget main = Screenshot(
      controller: screenshotController,
      child: Container(
        color: cardColor,
        margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        padding: const EdgeInsets.only(
          top: Base.BASE_PADDING,
          // bottom: Base.BASE_PADDING,
        ),
        child: EventMainComponent(
          screenshotController: screenshotController,
          event: widget.event,
          pagePubkey: widget.pagePubkey,
          textOnTap: widget.jumpable ? jumpToThread : null,
          showVideo: widget.showVideo,
          imageListMode: widget.imageListMode,
          showDetailBtn: widget.showDetailBtn,
          showLongContent: widget.showLongContent,
        ),
      ),
    );

    if (widget.event.kind == kind.EventKind.ZAP) {
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
    if (widget.event.kind == kind.EventKind.REPOST) {
      // try to find target event
      if (widget.event.content.contains("\"pubkey\"")) {
        try {
          var jsonMap = jsonDecode(widget.event.content);
          var repostEvent = Event.fromJson(jsonMap);
          RouterUtil.router(context, RouterPath.THREAD_DETAIL, repostEvent);
          return;
        } catch (e) {
          print(e);
        }
      }

      var eventRelation = EventRelation.fromEvent(widget.event);
      if (StringUtil.isNotBlank(eventRelation.rootId)) {
        var event = singleEventProvider.getEvent(eventRelation.rootId!);
        if (event != null) {
          RouterUtil.router(context, RouterPath.THREAD_DETAIL, event);
          return;
        }
      }
    }
    RouterUtil.router(context, RouterPath.THREAD_DETAIL, widget.event);
  }
}
