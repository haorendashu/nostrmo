import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';

import '../../client/nip19/nip19.dart';
import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';

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
  static const double IMAGE_WIDTH = 34;

  static const double HALF_IMAGE_WIDTH = 17;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    return Selector<MetadataProvider, Metadata?>(
      shouldRebuild: (previous, next) {
        return previous != next;
      },
      selector: (context, _metadataProvider) {
        return _metadataProvider.getMetadata(widget.event.pubKey);
      },
      builder: (context, metadata, child) {
        String nip19Name = Nip19.encodeSimplePubKey(widget.event.pubKey);

        Widget? imageWidget;
        if (metadata != null) {
          if (StringUtil.isNotBlank(metadata.picture)) {
            imageWidget = Image(
              image: NetworkImage(metadata.picture!),
              width: IMAGE_WIDTH,
            );
          }
        }

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
                width: IMAGE_WIDTH,
                height: IMAGE_WIDTH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(HALF_IMAGE_WIDTH),
                  color: Colors.grey,
                ),
                child: imageWidget,
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
      },
    );
  }
}
