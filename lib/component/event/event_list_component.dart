import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_relation.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/community_approved_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

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

  bool showCommunity;

  EventListComponent({
    required this.event,
    this.pagePubkey,
    this.jumpable = true,
    this.showVideo = false,
    this.imageListMode = true,
    this.showDetailBtn = true,
    this.showLongContent = false,
    this.showCommunity = true,
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
    var eventRelation = EventRelation.fromEvent(widget.event);

    Widget main = Screenshot(
      controller: screenshotController,
      child: Container(
        color: cardColor,
        margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        child: EventMainComponent(
          screenshotController: screenshotController,
          event: widget.event,
          pagePubkey: widget.pagePubkey,
          textOnTap: widget.jumpable ? jumpToThread : null,
          showVideo: widget.showVideo,
          imageListMode: widget.imageListMode,
          showDetailBtn: widget.showDetailBtn,
          showLongContent: widget.showLongContent,
          showCommunity: widget.showCommunity,
          eventRelation: eventRelation,
        ),
      ),
    );

    if (widget.event.kind == EventKind.ZAP) {
      main = EventBitcionIconComponent.wrapper(main);
    }

    Widget approvedWrap = Selector<CommunityApprovedProvider, bool>(
        builder: (context, approved, child) {
      if (approved) {
        return main;
      }

      return Container();
    }, selector: (context, _provider) {
      return _provider.check(widget.event.pubkey, widget.event.id,
          aId: eventRelation.aId);
    });

    if (widget.jumpable) {
      return GestureDetector(
        onTap: jumpToThread,
        child: approvedWrap,
      );
    } else {
      return approvedWrap;
    }
  }

  void jumpToThread() {
    if (widget.event.kind == EventKind.REPOST) {
      // try to find target event
      if (widget.event.content.contains("\"pubkey\"")) {
        try {
          var jsonMap = jsonDecode(widget.event.content);
          var repostEvent = Event.fromJson(jsonMap);
          RouterUtil.router(
              context, RouterPath.getThreadDetailPath(), repostEvent);
          return;
        } catch (e) {
          print(e);
        }
      }

      var eventRelation = EventRelation.fromEvent(widget.event);
      if (StringUtil.isNotBlank(eventRelation.rootId)) {
        var event = singleEventProvider.getEvent(eventRelation.rootId!,
            eventRelayAddr: eventRelation.rootRelayAddr);
        if (event != null) {
          RouterUtil.router(context, RouterPath.getThreadDetailPath(), event);
          return;
        }
      }
    }
    RouterUtil.router(context, RouterPath.getThreadDetailPath(), widget.event);
  }
}
