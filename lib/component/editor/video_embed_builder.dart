import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../content/content_video_component.dart';

class VideoEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    var url = embedContext.node.value.data as String;
    return ContentVideoComponent(url: url);
  }

  @override
  String get key => BlockEmbed.videoType;
}
