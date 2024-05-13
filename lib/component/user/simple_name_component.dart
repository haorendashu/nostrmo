import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';

class SimpleNameComponent extends StatefulWidget {
  static String getSimpleName(String pubkey, Metadata? metadata) {
    String? name;
    if (metadata != null) {
      if (StringUtil.isNotBlank(metadata.displayName)) {
        name = metadata.displayName;
      } else if (StringUtil.isNotBlank(metadata.name)) {
        name = metadata.name;
      }
    }
    if (StringUtil.isBlank(name)) {
      name = Nip19.encodeSimplePubKey(pubkey);
    }

    return name!;
  }

  String pubkey;

  TextStyle? textStyle;

  SimpleNameComponent({
    required this.pubkey,
    this.textStyle,
  });

  @override
  State<StatefulWidget> createState() {
    return _SimpleNameComponent();
  }
}

class _SimpleNameComponent extends State<SimpleNameComponent> {
  @override
  Widget build(BuildContext context) {
    return Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
      var name = SimpleNameComponent.getSimpleName(widget.pubkey, metadata);
      return Container(
        child: Text(
          name,
          style: widget.textStyle,
        ),
      );
    }, selector: (context, _provider) {
      return _provider.getMetadata(widget.pubkey);
    });
  }
}
