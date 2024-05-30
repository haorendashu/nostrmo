import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../client/event.dart';
import '../../client/zap/zap_info_util.dart';
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
    senderPubkey = ZapInfoUtil.parseSenderPubkey(widget.event);
  }

  @override
  Widget build(BuildContext context) {
    if (StringUtil.isBlank(senderPubkey)) {
      return Container();
    }

    if (eventId != widget.event.id) {
      senderPubkey = ZapInfoUtil.parseSenderPubkey(widget.event);
    }

    var zapNum = ZapInfoUtil.getNumFromZapEvent(widget.event);
    String zapNumStr = NumberFormatUtil.format(zapNum);

    var text = "zaped $zapNumStr sats";

    return ReactionEventItemComponent(
        pubkey: senderPubkey!, text: text, createdAt: widget.event.createdAt);
  }
}
