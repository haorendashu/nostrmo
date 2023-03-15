import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/util/string_util.dart';

import '../../client/nip19/nip19.dart';
import '../../consts/base.dart';
import '../../data/metadata.dart';
import 'metadata_top_component.dart';

class MetadataComponent extends StatefulWidget {
  String pubKey;

  Metadata? metadata;

  MetadataComponent({required this.pubKey, this.metadata});

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
    ));

    if (widget.metadata != null &&
        StringUtil.isNotBlank(widget.metadata!.about)) {
      mainList.add(
        Container(
          width: double.maxFinite,
          padding: EdgeInsets.only(
            top: Base.BASE_PADDING_HALF,
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
            bottom: Base.BASE_PADDING,
          ),
          child: Text(widget.metadata!.about!),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: mainList,
    );
  }
}
