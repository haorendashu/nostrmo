import 'package:flutter/material.dart';
import 'package:nostrmo/component/content/content_str_link_component.dart';

class ContentLinkComponent extends StatelessWidget {
  String link;

  ContentLinkComponent({required this.link});

  @override
  Widget build(BuildContext context) {
    return ContentStrLinkComponent(
      str: link,
      onTap: () {
        print("begin to open link $link");
      },
    );
  }
}
