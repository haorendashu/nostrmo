import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/consts/base.dart';

class EventTopComponent extends StatefulWidget {
  Event event;

  EventTopComponent({
    required this.event,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventTopComponent();
  }
}

class _EventTopComponent extends State<EventTopComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    String nip19Name = Nip19.encodeSimplePubKey(widget.event.pubKey);

    return Container(
      padding: EdgeInsets.only(
        top: Base.BASE_PADDING,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING_HALF,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: Base.BASE_PADDING_HALF),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: Text(
                      nip19Name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    margin: EdgeInsets.only(bottom: 2),
                  ),
                  Text(
                    GetTimeAgo.parse(DateTime.fromMillisecondsSinceEpoch(
                        widget.event.createdAt * 1000)),
                    style: TextStyle(
                      fontSize: smallTextSize,
                      color: themeData.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
