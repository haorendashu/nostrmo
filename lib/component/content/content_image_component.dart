import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ContentImageComponent extends StatelessWidget {
  String imageUrl;

  ContentImageComponent({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ),
    );
  }
}
