import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostrmo/component/content/content_component.dart';
import 'package:nostrmo/component/content/content_decoder.dart';
import 'package:nostrmo/component/event/simple_event_component.dart';
import 'package:nostrmo/component/group_identifier_inherited_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/single_event_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:pointycastle/export.dart' as pointycastle;
import 'package:provider/provider.dart';

import '../../component/user/user_pic_component.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../main.dart';
import '../../provider/setting_provider.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'dm_plaintext_handle.dart';

class DMDetailItemComponent extends StatefulWidget {
  String sessionPubkey;

  Event event;

  bool isLocal;

  Function? onLongPress;

  Function(String)? onRepledEventTap;

  DMDetailItemComponent({
    super.key,
    required this.sessionPubkey,
    required this.event,
    required this.isLocal,
    this.onLongPress,
    this.onRepledEventTap,
  });

  @override
  State<StatefulWidget> createState() {
    return _DMDetailItemComponent();
  }
}

class _DMDetailItemComponent extends State<DMDetailItemComponent>
    with DMPlaintextHandle {
  static const double IMAGE_WIDTH = 34;

  static const double BLANK_WIDTH = 50;

  String? replingEventId;

  String? replingEventRelay;

  @override
  void initState() {
    super.initState();
  }

  void handleReplingInfo() {
    replingEventId = null;
    replingEventRelay = null;

    for (var tag in widget.event.tags) {
      if (tag is List && tag.isNotEmpty) {
        if (tag[0] == "q") {
          if (tag.length > 1) {
            replingEventId = tag[1];
          }
          if (tag.length > 2) {
            replingEventRelay = tag[2];
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    handleReplingInfo();

    var _settingProvider = Provider.of<SettingProvider>(context);
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    Widget userHeadWidget = Container(
      margin: const EdgeInsets.only(top: 2),
      child: UserPicComponent(
        pubkey: widget.event.pubkey,
        width: IMAGE_WIDTH,
      ),
    );
    // var maxWidth = mediaDataCache.size.width;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    var hintColor = themeData.hintColor;

    String timeStr = GetTimeAgo.parse(
        DateTime.fromMillisecondsSinceEpoch(widget.event.createdAt * 1000));

    if (currentPlainEventId != widget.event.id) {
      plainContent = null;
    }

    var content = widget.event.content;
    if (widget.event.kind == EventKind.DIRECT_MESSAGE &&
        StringUtil.isBlank(plainContent)) {
      handleEncryptedText(widget.event, widget.sessionPubkey);
    }
    if (StringUtil.isNotBlank(plainContent)) {
      content = plainContent!;
    }
    content = content.replaceAll("\r", " ");
    content = content.replaceAll("\n", " ");

    var timeWidget = Text(
      timeStr,
      style: TextStyle(
        color: hintColor,
        fontSize: smallTextSize,
      ),
    );
    Widget enhancedIcon = Container();
    if (widget.event.kind == EventKind.PRIVATE_DIRECT_MESSAGE) {
      enhancedIcon = Container(
        margin: const EdgeInsets.only(
          left: Base.BASE_PADDING_HALF,
          right: Base.BASE_PADDING_HALF,
        ),
        child: Icon(
          Icons.enhanced_encryption,
          size: smallTextSize! + 2,
          color: hintColor,
        ),
      );
    }
    List<Widget> topList = [];
    if (widget.isLocal) {
      topList.add(enhancedIcon);
      topList.add(timeWidget);
    } else {
      topList.add(timeWidget);
      topList.add(enhancedIcon);
    }

    late Widget replyEventWidget;
    if (StringUtil.isNotBlank(replingEventId)) {
      if (StringUtil.isBlank(replingEventRelay)) {
        var groupIdentifier =
            GroupIdentifierInheritedWidget.getGroupIdentifier(context);
        if (groupIdentifier != null) {
          replingEventRelay = groupIdentifier.host;
        }
      }

      replyEventWidget = Selector<SingleEventProvider, Event?>(
          builder: (context, event, child) {
        if (event == null) {
          return Container();
        }

        return GestureDetector(
          onTap: () {
            if (widget.onRepledEventTap != null &&
                StringUtil.isNotBlank(replingEventId)) {
              widget.onRepledEventTap!(replingEventId!);
            }
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
            margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
            padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
            decoration: BoxDecoration(
              color: themeData.hintColor.withAlpha(50),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SimpleEventComponent(event),
          ),
        );
      }, selector: (context, provider) {
        return provider.getEvent(replingEventId!,
            eventRelayAddr: replingEventRelay);
      });
    } else {
      replyEventWidget = Container();
    }

    var contentWidget = Container(
      margin: const EdgeInsets.only(
        left: Base.BASE_PADDING_HALF,
        right: Base.BASE_PADDING_HALF,
      ),
      child: Column(
        crossAxisAlignment:
            !widget.isLocal ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: topList,
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.only(
              top: Base.BASE_PADDING_HALF - 1,
              right: Base.BASE_PADDING_HALF,
              bottom: Base.BASE_PADDING_HALF,
              left: Base.BASE_PADDING_HALF + 1,
            ),
            // constraints:
            //     BoxConstraints(maxWidth: (maxWidth - IMAGE_WIDTH) * 0.85),
            decoration: BoxDecoration(
              // color: Colors.red,
              color: mainColor.withOpacity(0.3),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: ContentComponent(
              content: content,
              event: widget.event,
              showLinkPreview: _settingProvider.linkPreview == OpenStatus.OPEN,
              smallest: true,
            ),
          ),
          replyEventWidget,
        ],
      ),
    );

    // if (!widget.isLocal) {
    userHeadWidget = GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.USER, widget.event.pubkey);
      },
      child: userHeadWidget,
    );
    // }

    List<Widget> list = [];
    if (widget.isLocal) {
      list.add(Container(width: BLANK_WIDTH));
      list.add(Expanded(child: contentWidget));
      list.add(userHeadWidget);
    } else {
      list.add(userHeadWidget);
      list.add(Expanded(child: contentWidget));
      list.add(Container(width: BLANK_WIDTH));
    }

    return GestureDetector(
      onLongPress: () {
        print("onLongPress!!!");
        print(widget.onLongPress);
        if (widget.onLongPress != null) {
          print("onLongPress 123");
          widget.onLongPress!();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: list,
        ),
      ),
    );
  }
}
