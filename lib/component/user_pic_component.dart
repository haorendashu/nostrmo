import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/metadata.dart';
import '../main.dart';
import '../provider/metadata_provider.dart';
import '../util/string_util.dart';

class UserPicComponent extends StatefulWidget {
  String pubkey;

  double width;

  UserPicComponent({
    required this.pubkey,
    required this.width,
  });

  @override
  State<StatefulWidget> createState() {
    return _UserPicComponent();
  }
}

class _UserPicComponent extends State<UserPicComponent> {
  @override
  Widget build(BuildContext context) {
    return Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        Widget? imageWidget;
        if (metadata != null) {
          if (StringUtil.isNotBlank(metadata.picture)) {
            imageWidget = CachedNetworkImage(
              imageUrl: metadata.picture!,
              width: widget.width,
              height: widget.width,
              fit: BoxFit.cover,
              placeholder: (context, url) => CircularProgressIndicator(),
              errorWidget: (context, url, error) => Icon(Icons.error),
              cacheManager: localCacheManager,
            );
          }
        }

        return Container(
          width: widget.width,
          height: widget.width,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.width / 2),
            color: Colors.grey,
          ),
          child: imageWidget,
        );
      },
      selector: (context, _provider) {
        return _provider.getMetadata(widget.pubkey);
      },
    );
  }
}
