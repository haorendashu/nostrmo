import 'package:flutter/material.dart';

import 'content_str_link_component.dart';

class ContentMentionUserComponent extends StatefulWidget {
  String pubkey;

  ContentMentionUserComponent({required this.pubkey});

  @override
  State<StatefulWidget> createState() {
    return _ContentMentionUserComponent();
  }
}

class _ContentMentionUserComponent extends State<ContentMentionUserComponent> {
  @override
  Widget build(BuildContext context) {
    return ContentStrLinkComponent(
      str: widget.pubkey,
      onTap: () {
        print("ContentMentionUserComponent ");
      },
    );
  }
}
