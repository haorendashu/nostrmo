import 'package:flutter/material.dart';
import 'package:nostrmo/component/content/content_str_link_component.dart';
import 'package:nostrmo/component/webview_router.dart';

import '../link_router_util.dart';

class ContentLinkComponent extends StatelessWidget {
  String link;

  String? title;

  ContentLinkComponent({
    required this.link,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ContentStrLinkComponent(
      str: title != null ? title! : link,
      onTap: () {
        LinkRouterUtil.router(context, link);
      },
    );
  }
}
