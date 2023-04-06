import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/zap_num_util.dart';
import 'package:nostrmo/component/event/zap_event_metadata_component.dart';
import 'package:nostrmo/component/simple_name_component.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';

class ZapEventMainComponent extends StatefulWidget {
  Event event;

  ZapEventMainComponent({required this.event});

  @override
  State<StatefulWidget> createState() {
    return _ZapEventMainComponent();
  }
}

class _ZapEventMainComponent extends State<ZapEventMainComponent> {
  static const double IMAGE_WIDTH = 20;

  String? senderPubkey;

  @override
  void initState() {
    super.initState();
    String? zapRequestEventStr;
    for (var tag in widget.event.tags) {
      if (tag is List<dynamic> && tag.length > 1) {
        var key = tag[0];
        if (key == "description") {
          zapRequestEventStr = tag[1];
        }
      }
    }

    if (StringUtil.isNotBlank(zapRequestEventStr)) {
      var eventJson = jsonDecode(zapRequestEventStr!);
      var zapRequestEvent = Event.fromJson(eventJson);
      senderPubkey = zapRequestEvent.pubKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    List<Widget> list = [];

    list.add(ZapEventMetadataComponent(pubkey: senderPubkey!));

    var zapNum = ZapNumUtil.getNumFromZapEvent(widget.event);
    String zapNumStr = zapNum.toString();
    if (zapNum > 1000000) {
      zapNumStr = (zapNum / 1000000).toStringAsFixed(1) + "m";
    } else if (zapNum > 1000) {
      zapNumStr = (zapNum / 1000).toStringAsFixed(1) + "k";
    }

    list.add(Text(" Zap $zapNumStr "));

    list.add(Text(
      GetTimeAgo.parse(
          DateTime.fromMillisecondsSinceEpoch(widget.event.createdAt * 1000)),
      style: TextStyle(
        fontSize: smallTextSize,
        color: themeData.hintColor,
      ),
    ));

    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: Row(
        children: list,
      ),
    );
  }
}
