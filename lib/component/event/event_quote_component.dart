import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/nip51/follow_set.dart';
import 'package:nostrmo/provider/replaceable_event_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../provider/single_event_provider.dart';
import '../../util/router_util.dart';
import '../cust_state.dart';
import '../follow_set_card_component.dart';
import 'event_follow_set_public_contacts_component.dart';
import 'event_main_component.dart';

class EventQuoteComponent extends StatefulWidget {
  Event? event;

  String? id;

  AId? aId;

  String? eventRelayAddr;

  bool showVideo;

  List<String>? relays;

  EventQuoteComponent({
    this.event,
    this.id,
    this.aId,
    this.eventRelayAddr,
    this.showVideo = false,
    this.relays,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventQuoteComponent();
  }
}

class _EventQuoteComponent extends CustState<EventQuoteComponent> {
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var boxDecoration = BoxDecoration(
      color: cardColor,
      boxShadow: [
        BoxShadow(
          color: themeData.shadowColor,
          offset: const Offset(0, 0),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ],
    );

    if (widget.event != null) {
      return buildEventWidget(widget.event!, cardColor, boxDecoration);
    }

    if (widget.aId != null) {
      return Selector<ReplaceableEventProvider, Event?>(
        builder: (context, event, child) {
          if (event == null) {
            return buildBlankWidget(boxDecoration);
          }

          return buildEventWidget(event, cardColor, boxDecoration);
        },
        selector: (context, _provider) {
          return _provider.getEvent(widget.aId!, relays: widget.relays);
        },
      );
    }

    return Selector<SingleEventProvider, Event?>(
      builder: (context, event, child) {
        if (event == null) {
          return buildBlankWidget(boxDecoration);
        }

        return buildEventWidget(event, cardColor, boxDecoration);
      },
      selector: (context, _provider) {
        return _provider.getEvent(widget.id!,
            eventRelayAddr: widget.eventRelayAddr);
      },
    );
  }

  Widget buildEventWidget(
      Event event, Color cardColor, BoxDecoration boxDecoration) {
    if (event.kind == EventKind.STORAGE_SHARED_FILE ||
        event.kind == EventKind.FILE_HEADER) {
      return EventMainComponent(
        screenshotController: screenshotController,
        event: event,
        showReplying: false,
        textOnTap: () {
          jumpToThread(event);
        },
        showVideo: widget.showVideo,
        imageListMode: true,
        inQuote: true,
      );
    } else if (event.kind == EventKind.FOLLOW_SETS ||
        event.kind == EventKind.GENERIC_LISTS ||
        event.kind == EventKind.STARTER_PACKS ||
        event.kind == EventKind.MEDIA_STARTER_PACKS) {
      // log(jsonEncode(event.toJson()));
      var followSet = FollowSet.getPublicFollowSet(event);

      return Container(
        padding: const EdgeInsets.all(Base.BASE_PADDING),
        margin: const EdgeInsets.all(Base.BASE_PADDING),
        decoration: boxDecoration,
        // child: EventFollowSetPublicContactsComponent(followSet, event.pubkey),
        child: FollowSetCardComponent(followSet),
      );
    }

    return Screenshot(
      controller: screenshotController,
      child: Container(
        padding: const EdgeInsets.only(top: Base.BASE_PADDING),
        margin: const EdgeInsets.all(Base.BASE_PADDING),
        decoration: boxDecoration,
        child: GestureDetector(
          onTap: () {
            jumpToThread(event);
          },
          behavior: HitTestBehavior.translucent,
          child: EventMainComponent(
            screenshotController: screenshotController,
            event: event,
            showReplying: false,
            textOnTap: () {
              jumpToThread(event);
            },
            showVideo: widget.showVideo,
            imageListMode: true,
            inQuote: true,
          ),
        ),
      ),
    );
  }

  Widget buildBlankWidget(BoxDecoration boxDecoration) {
    return Container(
      margin: const EdgeInsets.all(Base.BASE_PADDING),
      height: 60,
      decoration: boxDecoration,
      child: Center(child: Text(S.of(context).Note_loading)),
    );
  }

  void jumpToThread(Event event) {
    RouterUtil.router(context, RouterPath.getThreadDetailPath(), event);
  }

  @override
  Future<void> onReady(BuildContext context) async {}
}
