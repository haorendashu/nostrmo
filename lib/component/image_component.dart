import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/platform_util.dart';

import '../main.dart';

class ImageComponent extends StatelessWidget {
  String imageUrl;

  double? width;

  double? height;

  BoxFit? fit;

  PlaceholderWidgetBuilder? placeholder;

  int? memCacheWidth;

  int? memCacheHeight;

  ImageComponent({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      errorWidget: (context, url, error) => Icon(Icons.error),
      cacheManager: imageLocalCacheManager,
      // imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
    );
  }
}
