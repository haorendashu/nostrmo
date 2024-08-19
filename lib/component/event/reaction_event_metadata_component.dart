import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/component/user/user_pic_component.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../data/metadata.dart';
import '../../main.dart';
import '../../provider/metadata_provider.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import '../image_component.dart';
import '../user/simple_name_component.dart';

class ReactionEventMetadataComponent extends StatefulWidget {
  String pubkey;

  ReactionEventMetadataComponent({
    required this.pubkey,
  });

  @override
  State<StatefulWidget> createState() {
    return _ReactionEventMetadataComponent();
  }
}

class _ReactionEventMetadataComponent
    extends State<ReactionEventMetadataComponent> {
  static const double IMAGE_WIDTH = 20;

  @override
  Widget build(BuildContext context) {
    return Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
      List<Widget> list = [];

      var name = SimpleNameComponent.getSimpleName(widget.pubkey, metadata);

      list.add(UserPicComponent(
        pubkey: widget.pubkey,
        width: IMAGE_WIDTH,
        metadata: metadata,
      ));

      list.add(Container(
        margin: EdgeInsets.only(left: 5),
        child: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      return GestureDetector(
        onTap: () {
          RouterUtil.router(context, RouterPath.USER, widget.pubkey);
        },
        child: Container(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: list,
          ),
        ),
      );
    }, selector: (context, _provider) {
      return _provider.getMetadata(widget.pubkey);
    });
  }
}
