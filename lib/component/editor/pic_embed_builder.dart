import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nostrmo/consts/base64.dart';

import '../image_component.dart';

class PicEmbedBuilder extends EmbedBuilder {
  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    var imageUrl = node.value.data as String;
    if (imageUrl.indexOf("http") == 0 || imageUrl.indexOf(BASE64.PREFIX) == 0) {
      // netword image
      return ImageComponent(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => CircularProgressIndicator(),
      );
    } else {
      // local image
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
      );
    }
  }

  @override
  String get key => BlockEmbed.imageType;
}
