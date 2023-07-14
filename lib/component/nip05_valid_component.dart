import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../consts/nip05status.dart';
import '../provider/metadata_provider.dart';

class Nip05ValidComponent extends StatefulWidget {
  String pubkey;

  Nip05ValidComponent({required this.pubkey});

  @override
  State<StatefulWidget> createState() {
    return _Nip05ValidComponent();
  }
}

class _Nip05ValidComponent extends State<Nip05ValidComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    return Selector<MetadataProvider, int>(
        builder: (context, nip05Status, child) {
      var iconData = Icons.check_circle;
      if (nip05Status == Nip05Status.NIP05_NOT_FOUND || nip05Status == Nip05Status.METADATA_NOT_FOUND) {
        // iconData = Icons.error;
        return Container(width: 0,height: 0,);
      }

      Color iconColor = Colors.red;
      if (nip05Status == Nip05Status.NIP05_NOT_VALIDED) {
        iconColor = Colors.yellow;
      } else if (nip05Status == Nip05Status.NIP05_VALIDED) {
        iconColor = mainColor;
      }

      return Icon(
        iconData,
        color: iconColor,
        size: smallTextSize,
      );
    }, selector: (context, _provider) {
      return _provider.getNip05Status(widget.pubkey);
    });
  }
}
