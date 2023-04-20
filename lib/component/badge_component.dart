import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../client/nip58/badge_definition.dart';
import '../main.dart';
import '../provider/badge_definition_provider.dart';
import '../util/string_util.dart';

class BedgeComponent extends StatelessWidget {
  static const double IMAGE_WIDTH = 28;

  BadgeDefinition badgeDefinition;

  BedgeComponent({
    required this.badgeDefinition,
  });

  @override
  Widget build(BuildContext context) {
    var imagePath = badgeDefinition.thumb;
    if (StringUtil.isBlank(imagePath)) {
      imagePath = badgeDefinition.image;
    }

    Widget? imageWidget;
    if (StringUtil.isNotBlank(imagePath)) {
      imageWidget = CachedNetworkImage(
        imageUrl: imagePath!,
        width: IMAGE_WIDTH,
        height: IMAGE_WIDTH,
        fit: BoxFit.cover,
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
        cacheManager: localCacheManager,
      );
    }

    var main = Container(
      alignment: Alignment.center,
      height: IMAGE_WIDTH,
      width: IMAGE_WIDTH,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
        color: Colors.grey,
      ),
      child: imageWidget,
    );

    return main;
  }
}
