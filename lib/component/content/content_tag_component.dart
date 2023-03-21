import 'package:flutter/material.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';

import 'content_str_link_component.dart';

class ContentTagComponent extends StatelessWidget {
  String tag;

  ContentTagComponent({required this.tag});

  @override
  Widget build(BuildContext context) {
    return ContentStrLinkComponent(
      str: tag,
      onTap: () {
        // RouterUtil.router(context, RouterPath.TAG_DETAIL, tag);
      },
    );
  }
}
