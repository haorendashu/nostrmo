import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/component/name_component.dart';
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
  String? pagePubkey;

  EventTopComponent({
    required this.event,
    this.pagePubkey,
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
        var themeData = Theme.of(context);

        Widget? imageWidget;
        if (metadata != null) {
          if (StringUtil.isNotBlank(metadata.picture)) {
            imageWidget = CachedNetworkImage(
              imageUrl: metadata.picture!,
              width: IMAGE_WIDTH,
              height: IMAGE_WIDTH,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            );
          }
        }

        return Container(
          padding: const EdgeInsets.only(
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
                  padding: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        child: jumpWrap(
                          NameComponnet(
                            pubkey: widget.event.pubKey,
                            metadata: metadata,
                          ),
                        ),
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
        // disable jump when in same user page.
        if (widget.pagePubkey == widget.event.pubKey) {
          return;
        }

        RouterUtil.router(context, RouterPath.USER, widget.event.pubKey);
      },
      child: c,
    );
  }
}
