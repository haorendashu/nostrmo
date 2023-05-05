import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../client/nip19/nip19.dart';
import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../util/string_util.dart';
import '../content/content_decoder.dart';
import 'metadata_top_component.dart';
import 'user_badges_component.dart';

class MetadataComponent extends StatefulWidget {
  String pubKey;

  Metadata? metadata;

  bool jumpable;

  bool showBadges;

  bool userPicturePreview;

  MetadataComponent({
    required this.pubKey,
    this.metadata,
    this.jumpable = false,
    this.showBadges = false,
    this.userPicturePreview = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _MetadataComponent();
  }
}

class _MetadataComponent extends State<MetadataComponent> {
  @override
  Widget build(BuildContext context) {
    List<Widget> mainList = [];

    mainList.add(MetadataTopComponent(
      pubkey: widget.pubKey,
      metadata: widget.metadata,
      jumpable: widget.jumpable,
      userPicturePreview: widget.userPicturePreview,
    ));

    if (widget.showBadges) {
      mainList.add(UserBadgesComponent(
        pubkey: widget.pubKey,
      ));
    }

    if (widget.metadata != null &&
        StringUtil.isNotBlank(widget.metadata!.about)) {
      mainList.add(
        Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(
            top: Base.BASE_PADDING_HALF,
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
            bottom: Base.BASE_PADDING,
          ),
          // child: Text(widget.metadata!.about!),
          child: Container(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: ContentDecoder.decode(
                context,
                widget.metadata!.about!,
                null,
                showLinkPreview: false,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: mainList,
    );
  }
}
