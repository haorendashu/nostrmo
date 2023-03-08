import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/component/event/event_top_component.dart';

import '../../consts/base.dart';

class EventListComponent extends StatefulWidget {
  Event event;

  EventListComponent({required this.event});

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EventTopComponent(
            event: widget.event,
          ),
          Container(
            width: double.maxFinite,
            padding: EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
              bottom: Base.BASE_PADDING,
            ),
            child: Text(widget.event.content),
          )
        ],
      ),
    );
  }
}
