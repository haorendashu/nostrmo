import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';

import '../../consts/base.dart';
import 'reaction_event_metadata_component.dart';

class ReactionEventItemComponent extends StatefulWidget {
  String pubkey;

  String text;

  int createdAt;

  ReactionEventItemComponent({
    required this.pubkey,
    required this.text,
    required this.createdAt,
  });

  @override
  State<StatefulWidget> createState() {
    return _ReactionEventItemComponent();
  }
}

class _ReactionEventItemComponent extends State<ReactionEventItemComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    List<Widget> list = [];

    list.add(ReactionEventMetadataComponent(pubkey: widget.pubkey));

    list.add(Text(" " + widget.text + " "));

    list.add(Text(
      GetTimeAgo.parse(
          DateTime.fromMillisecondsSinceEpoch(widget.createdAt * 1000)),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: list,
        ),
      ),
    );
  }
}
