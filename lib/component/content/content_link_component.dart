import 'package:flutter/material.dart';
import 'package:nostrmo/component/content/content_str_link_component.dart';
import 'package:nostrmo/component/webview_router.dart';

class ContentLinkComponent extends StatelessWidget {
  String link;

  ContentLinkComponent({required this.link});

  @override
  Widget build(BuildContext context) {
    return ContentStrLinkComponent(
      str: link,
      onTap: () {
        WebViewRouter.open(context, link);
      },
    );
  }
}
