import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import '../user/name_component.dart';
import '../user/user_pic_component.dart';

class SimpleEventComponent extends StatefulWidget {
  Event event;

  SimpleEventComponent(this.event);

  @override
  State<StatefulWidget> createState() {
    return _SimpleEventComponent();
  }
}

class _SimpleEventComponent extends State<SimpleEventComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    return Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserPicComponent(
            pubkey: widget.event.pubkey,
            width: 22,
            metadata: metadata,
          ),
          Container(
            margin: const EdgeInsets.only(
              left: Base.BASE_PADDING_HALF,
            ),
            child: NameComponent(
              pubkey: widget.event.pubkey,
              showNip05: false,
              showName: false,
              metadata: metadata,
            ),
          ),
          const Text(": "),
          Flexible(
            child: Text(
              widget.event.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }, selector: (context, provider) {
      return provider.getMetadata(widget.event.pubkey);
    });
  }
}
