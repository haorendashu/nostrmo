import 'package:flutter/material.dart';

class MediaDataCache {
  late Size size;

  late EdgeInsets padding;

  void update(BuildContext context) {
    var mediaData = MediaQuery.of(context);
    size = mediaData.size;
    padding = mediaData.padding;
  }
}
