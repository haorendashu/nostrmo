import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nostrmo/component/content/content_tag_component.dart';

import 'cust_embed_types.dart';

class TagEmbedBuilder extends EmbedBuilder {
  bool get expanded => false;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    var tag = node.value.data;
    return AbsorbPointer(
      child: Container(
        margin: const EdgeInsets.only(
          left: 4,
          right: 4,
        ),
        child: ContentTagComponent(tag: "#" + tag),
      ),
    );
  }

  @override
  String get key => CustEmbedTypes.tag;
}
