import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/component/simple_date_component.dart';
import 'package:nostrmo/component/user/name_component.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';

import '../../client/event.dart';
import '../../client/nip19/nip19.dart';
import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../main.dart';
import '../../provider/metadata_provider.dart';
import '../image_component.dart';
import '../nip05_valid_component.dart';

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
  static const double IMAGE_WIDTH = 36;

  static const double HALF_IMAGE_WIDTH = 18;

  String? pubkey;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    pubkey = widget.event.pubkey;
    // if this is the zap event, change the pubkey from the zap tag info
    if (widget.event.kind == EventKind.ZAP) {
      for (var tag in widget.event.tags) {
        if (tag[0] == "description" && widget.event.tags.length > 1) {
          var description = tag[1];
          var jsonMap = jsonDecode(description);
          var sourceEvent = Event.fromJson(jsonMap);
          if (StringUtil.isNotBlank(sourceEvent.pubkey)) {
            pubkey = sourceEvent.pubkey;
          }
        }
      }
    }

    return Selector<MetadataProvider, Metadata?>(
      shouldRebuild: (previous, next) {
        return previous != next;
      },
      selector: (context, _metadataProvider) {
        return _metadataProvider.getMetadata(pubkey!);
      },
      builder: (context, metadata, child) {
        var themeData = Theme.of(context);

        Widget? imageWidget;
        String nip05Text = Nip19.encodeSimplePubKey(pubkey!);

        if (metadata != null) {
          if (StringUtil.isNotBlank(metadata.picture)) {
            imageWidget = ImageComponent(
              imageUrl: metadata.picture!,
              width: IMAGE_WIDTH,
              height: IMAGE_WIDTH,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(),
            );
          }

          if (StringUtil.isNotBlank(metadata.nip05)) {
            nip05Text = metadata.nip05!;
          }
        }

        return Container(
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
            bottom: Base.BASE_PADDING_HALF,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              jumpWrap(Container(
                width: IMAGE_WIDTH,
                height: IMAGE_WIDTH,
                margin: EdgeInsets.only(top: 4),
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
                      Row(
                        children: [
                          jumpWrap(
                            NameComponent(
                              pubkey: widget.event.pubkey,
                              metadata: metadata,
                              maxLines: 1,
                              textOverflow: TextOverflow.ellipsis,
                              showNip05: false,
                              showName: false,
                            ),
                          ),
                          Expanded(
                            child: Container(),
                          ),
                          // SimpleDateComponent(widget.event.createdAt),
                          Text(
                            GetTimeAgo.parse(
                              DateTime.fromMillisecondsSinceEpoch(
                                  widget.event.createdAt * 1000),
                              pattern: "dd MMM, yyyy",
                            ),
                            style: TextStyle(
                              fontSize: smallTextSize,
                              color: themeData.hintColor,
                            ),
                          ),
                        ],
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: nip05Text,
                              style: TextStyle(
                                fontSize: smallTextSize,
                                color: themeData.hintColor,
                              ),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.ideographic,
                              child: Container(
                                margin: const EdgeInsets.only(left: 3),
                                child: Nip05ValidComponent(pubkey: pubkey!),
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
        if (widget.pagePubkey == widget.event.pubkey) {
          return;
        }

        RouterUtil.router(context, RouterPath.USER, pubkey);
      },
      child: c,
    );
  }
}
