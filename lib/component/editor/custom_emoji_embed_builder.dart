import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nostrmo/component/content/content_custom_emoji_component.dart';
import 'package:nostrmo/component/editor/cust_embed_types.dart';
import 'package:nostrmo/data/custom_emoji.dart';

class CustomEmojiEmbedBuilder extends EmbedBuilder {
  bool get expanded => false;

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    var customEmoji = node.value.data as CustomEmoji;
    return ContentCustomEmojiComponent(imagePath: customEmoji.filepath!);
  }

  @override
  String get key => CustEmbedTypes.custom_emoji;
}
