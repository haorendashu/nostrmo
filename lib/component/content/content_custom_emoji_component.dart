import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class ContentCustomEmojiComponent extends StatelessWidget {
  final String imagePath;

  ContentCustomEmojiComponent({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    // var themeData = Theme.of(context);
    // var fontSize = themeData.textTheme.bodyMedium!.fontSize;
    if (imagePath.indexOf("http") == 0) {
      // netword image
      return Container(
        constraints: BoxConstraints(maxWidth: 80, maxHeight: 80),
        child: CachedNetworkImage(
          // width: fontSize! * 2,
          imageUrl: imagePath,
          // fit: imageBoxFix,
          placeholder: (context, url) => Container(),
          errorWidget: (context, url, error) => Icon(Icons.error),
          cacheManager: localCacheManager,
        ),
      );
    } else {
      // local image
      return Container(
        constraints: BoxConstraints(maxWidth: 80, maxHeight: 80),
        child: Image.file(
          File(imagePath),
          // fit: BoxFit.fitWidth,
        ),
      );
    }
  }
}
