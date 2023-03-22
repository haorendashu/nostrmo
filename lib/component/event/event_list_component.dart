import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';

import '../../consts/base.dart';
import 'event_main_component.dart';

class EventListComponent extends StatefulWidget {
  Event event;

  String? pagePubkey;

  EventListComponent({
    required this.event,
    this.pagePubkey,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventListComponent();
  }
}

class _EventListComponent extends State<EventListComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    return Container(
      color: cardColor,
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      padding: EdgeInsets.only(
        top: Base.BASE_PADDING,
        // bottom: Base.BASE_PADDING,
      ),
      child: EventMainComponent(
        event: widget.event,
        pagePubkey: widget.pagePubkey,
      ),
    );
  }
}
