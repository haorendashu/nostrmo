import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../client/event.dart';
import '../../client/zap/zap_num_util.dart';
import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import '../../util/number_format_util.dart';
import '../../util/spider_util.dart';
import '../../util/string_util.dart';
import 'reaction_event_item_component.dart';

class ZapEventMainComponent extends StatefulWidget {
  Event event;

  ZapEventMainComponent({required this.event});

  @override
  State<StatefulWidget> createState() {
    return _ZapEventMainComponent();
  }
}

class _ZapEventMainComponent extends State<ZapEventMainComponent> {
  String? senderPubkey;

  late String eventId;

  @override
  void initState() {
    super.initState();

    eventId = widget.event.id;
    parseSenderPubkey();
  }

  void parseSenderPubkey() {
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
      try {
        var eventJson = jsonDecode(zapRequestEventStr!);
        var zapRequestEvent = Event.fromJson(eventJson);
        senderPubkey = zapRequestEvent.pubKey;
      } catch (e) {
        log("jsonDecode zapRequest error ${e.toString()}");
        senderPubkey =
            SpiderUtil.subUntil(zapRequestEventStr!, "pubkey\":\"", "\"");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (StringUtil.isBlank(senderPubkey)) {
      return Container();
    }

    if (eventId != widget.event.id) {
      parseSenderPubkey();
    }

    var zapNum = ZapNumUtil.getNumFromZapEvent(widget.event);
    String zapNumStr = NumberFormatUtil.format(zapNum);

    var text = "zaped $zapNumStr sats";

    return ReactionEventItemComponent(
        pubkey: senderPubkey!, text: text, createdAt: widget.event.createdAt);
  }
}
