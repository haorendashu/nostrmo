import 'package:flutter/material.dart';

import 'content_str_link_component.dart';

class ContentTagComponent extends StatelessWidget {
  String tag;

  ContentTagComponent({required this.tag});

  @override
  Widget build(BuildContext context) {
    return ContentStrLinkComponent(
      str: tag,
      onTap: () {
        print("begin to open tag page $tag");
      },
    );
  }
}
