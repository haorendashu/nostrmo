import 'package:flutter/material.dart';
import 'package:nostr_sdk/event_relation.dart';
import 'package:nostrmo/component/user/simple_metadata_component.dart';
import 'package:nostrmo/component/user/simple_name_component.dart';
import 'package:nostrmo/component/user/user_pic_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:flutter_seekbar/flutter_seekbar.dart';

import '../user/name_component.dart';

class ZapSplitInputItemComponent extends StatefulWidget {
  EventZapInfo eventZapInfo;

  Function recountWeightAndRefresh;

  ZapSplitInputItemComponent(this.eventZapInfo, this.recountWeightAndRefresh);

  @override
  State<StatefulWidget> createState() {
    return _ZapSplitInputItemComponent();
  }
}

class _ZapSplitInputItemComponent extends State<ZapSplitInputItemComponent> {
  @override
  Widget build(BuildContext context) {
    var pubkey = widget.eventZapInfo.pubkey;
    List<Widget> list = [];

    list.add(UserPicComponent(pubkey: pubkey, width: 46));

    list.add(Container(
      padding: EdgeInsets.only(left: Base.BASE_PADDING),
      width: 120,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SimpleNameComponent(
            pubkey: pubkey,
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text("${(widget.eventZapInfo.weight * 100).toStringAsFixed(0)}%")
        ],
      ),
    ));

    list.add(Expanded(
      child: Container(
        child: SeekBar(
          min: 0.01,
          max: 1,
          value: widget.eventZapInfo.weight,
          semanticsValue: "${widget.eventZapInfo.weight}",
          alwaysShowBubble: true,
          onValueChanged: (pv) {
            widget.eventZapInfo.weight = pv.value;
            widget.recountWeightAndRefresh();
          },
        ),
      ),
    ));

    return Container(
      child: Row(
        children: list,
      ),
    );
  }
}
