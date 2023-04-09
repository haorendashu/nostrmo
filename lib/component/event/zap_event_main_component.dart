import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/util/number_format_util.dart';
import 'package:provider/provider.dart';

import '../../client/zap_num_util.dart';
import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
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
    if (StringUtil.isBlank(senderPubkey)) {
      return Container();
    }

    var zapNum = ZapNumUtil.getNumFromZapEvent(widget.event);
    String zapNumStr = NumberFormatUtil.format(zapNum);

    var text = "zaped $zapNumStr sats";

    return ReactionEventItemComponent(
        pubkey: senderPubkey!, text: text, createdAt: widget.event.createdAt);
  }
}
