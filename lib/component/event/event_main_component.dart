import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../client/event_kind.dart' as kind;
import '../../client/event_relation.dart';
import '../../client/nip19/nip19.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import '../../provider/setting_provider.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';
import '../content/content_decoder.dart';
import 'event_quote_component.dart';
import 'event_reactions_component.dart';
import 'event_top_component.dart';

class EventMainComponent extends StatefulWidget {
  ScreenshotController screenshotController;

  Event event;

  String? pagePubkey;

  bool showReplying;

  Function? textOnTap;

  bool showVideo;

  EventMainComponent({
    required this.screenshotController,
    required this.event,
    this.pagePubkey,
    this.showReplying = true,
    this.textOnTap,
    this.showVideo = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventMainComponent();
  }
}

class _EventMainComponent extends State<EventMainComponent> {
  late EventRelation eventRelation;

  @override
  void initState() {
    super.initState();
    eventRelation = EventRelation.fromEvent(widget.event);
  }

  @override
  Widget build(BuildContext context) {
    var _settingProvider = Provider.of<SettingProvider>(context);
    if (eventRelation.id != widget.event.id) {
      // change when thead root load lazy
      eventRelation = EventRelation.fromEvent(widget.event);
    }

    bool imagePreview = _settingProvider.imagePreview == null ||
        _settingProvider.imagePreview == OpenStatus.OPEN;
    bool videoPreview = widget.showVideo;
    if (_settingProvider.videoPreview != null) {
      videoPreview = _settingProvider.videoPreview == OpenStatus.OPEN;
    }

    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    Event? repostEvent;
    if (widget.event.kind == kind.EventKind.REPOST &&
        widget.event.content.contains("\"pubkey\"")) {
      try {
        var jsonMap = jsonDecode(widget.event.content);
        repostEvent = Event.fromJson(jsonMap);
      } catch (e) {
        print(e);
      }
    }

    List<Widget> list = [];
    if (widget.event.kind == kind.EventKind.REPOST) {
      list.add(Container(
        alignment: Alignment.centerLeft,
        child: Text("Boost:"),
      ));
      if (repostEvent != null) {
        list.add(EventQuoteComponent(
          event: repostEvent,
          showVideo: widget.showVideo,
        ));
      } else if (StringUtil.isNotBlank(eventRelation.rootId)) {
        list.add(EventQuoteComponent(
          id: eventRelation.rootId,
          showVideo: widget.showVideo,
        ));
      } else {
        list.add(
          Container(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: ContentDecoder.decode(
                context,
                null,
                widget.event,
                textOnTap: widget.textOnTap,
                showImage: imagePreview,
                showVideo: videoPreview,
                showLinkPreview:
                    _settingProvider.linkPreview == OpenStatus.OPEN,
              ),
            ),
          ),
        );
      }
    } else {
      if (widget.showReplying && eventRelation.tagPList.isNotEmpty) {
        var textStyle = TextStyle(
          color: hintColor,
          fontSize: smallTextSize,
        );
        List<Widget> replyingList = [];
        var length = eventRelation.tagPList.length;
        replyingList.add(Text(
          "Replying: ",
          style: textStyle,
        ));
        for (var index = 0; index < length; index++) {
          var p = eventRelation.tagPList[index];
          var isLast = index < length - 1 ? false : true;
          replyingList.add(EventReplyingcomponent(pubkey: p));
          if (!isLast) {
            replyingList.add(Text(
              " & ",
              style: textStyle,
            ));
          }
        }
        list.add(Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(
            bottom: Base.BASE_PADDING_HALF,
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: replyingList,
          ),
        ));
      }
      // list.add(Container(
      //   width: double.maxFinite,
      //   child: Text(widget.event.content),
      // ));
      list.add(
        Container(
          width: double.maxFinite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: ContentDecoder.decode(
              context,
              null,
              widget.event,
              textOnTap: widget.textOnTap,
              showImage: imagePreview,
              showVideo: videoPreview,
              showLinkPreview: _settingProvider.linkPreview == OpenStatus.OPEN,
            ),
          ),
        ),
      );
      list.add(EventReactionsComponent(
        screenshotController: widget.screenshotController,
        event: widget.event,
        eventRelation: eventRelation,
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EventTopComponent(
          event: widget.event,
          pagePubkey: widget.pagePubkey,
        ),
        Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: list,
          ),
        ),
      ],
    );
  }
}

class EventReplyingcomponent extends StatefulWidget {
  String pubkey;

  EventReplyingcomponent({required this.pubkey});

  @override
  State<StatefulWidget> createState() {
    return _EventReplyingcomponent();
  }
}

class _EventReplyingcomponent extends State<EventReplyingcomponent> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.USER, widget.pubkey);
      },
      child: Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
          var themeData = Theme.of(context);
          var hintColor = themeData.hintColor;
          var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
          String nip19Name = Nip19.encodeSimplePubKey(widget.pubkey);
          String displayName = nip19Name;

          if (metadata != null) {
            if (StringUtil.isNotBlank(metadata.displayName)) {
              displayName = metadata.displayName!;
            }
          }

          return Text(
            displayName,
            style: TextStyle(
              color: hintColor,
              fontSize: smallTextSize,
              // fontWeight: FontWeight.bold,
            ),
          );
        },
        selector: (context, _provider) {
          return _provider.getMetadata(widget.pubkey);
        },
      ),
    );
  }
}
