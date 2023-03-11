import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';
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
    var hintColor = themeData.hintColor;
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
        String displayName = nip19Name;
        String name = "";

        Widget? imageWidget;
        if (metadata != null) {
          if (StringUtil.isNotBlank(metadata.picture)) {
            imageWidget = CachedNetworkImage(
              imageUrl: metadata.picture!,
              width: IMAGE_WIDTH,
              height: IMAGE_WIDTH,
              fit: BoxFit.cover,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
            );
          }
          if (StringUtil.isNotBlank(metadata.displayName)) {
            displayName = metadata.displayName!;
          }
          if (StringUtil.isNotBlank(metadata.name)) {
            name = "@" + metadata.name!;
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
              jumpWrap(Container(
                width: IMAGE_WIDTH,
                height: IMAGE_WIDTH,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(HALF_IMAGE_WIDTH),
                  color: Colors.grey,
                ),
                child: imageWidget,
              )),
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: jumpWrap(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(left: 2),
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hintColor,
                                  ),
                                ),
                              ),
                            ],
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

  Widget jumpWrap(Widget c) {
    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.USER, widget.event.pubKey);
      },
      child: c,
    );
  }
}
