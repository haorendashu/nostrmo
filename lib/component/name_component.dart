import 'package:flutter/material.dart';
import 'package:nostrmo/data/metadata.dart';

import '../client/nip19/nip19.dart';
import '../util/string_util.dart';

class NameComponnet extends StatefulWidget {
  String pubkey;

  Metadata? metadata;

  bool showNip05;

  double? fontSize;

  Color? fontColor;

  NameComponnet({
    required this.pubkey,
    this.metadata,
    this.showNip05 = true,
    this.fontSize,
    this.fontColor,
  });

  @override
  State<StatefulWidget> createState() {
    return _NameComponnet();
  }
}

class _NameComponnet extends State<NameComponnet> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    Color hintColor = themeData.hintColor;
    var metadata = widget.metadata;
    String nip19Name = Nip19.encodeSimplePubKey(widget.pubkey);
    String displayName = nip19Name;
    String name = "";
    if (widget.fontColor != null) {
      hintColor = widget.fontColor!;
    }

    bool hasNip05 = false;
    if (metadata != null) {
      if (StringUtil.isNotBlank(metadata.displayName)) {
        displayName = metadata.displayName!;
      }
      if (StringUtil.isNotBlank(metadata.name)) {
        name = "@" + metadata.name!;
      }
      if (StringUtil.isNotBlank(metadata.nip05)) {
        hasNip05 = true;
      }
    }

    List<Widget> nameList = [
      Text(
        displayName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: widget.fontSize,
          color: widget.fontColor,
        ),
      ),
      Container(
        margin: EdgeInsets.only(left: 2),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: hintColor,
          ),
        ),
      ),
    ];
    if (hasNip05 && widget.showNip05) {
      nameList.add(Container(
        margin: EdgeInsets.only(left: 3),
        child: Icon(
          Icons.check_circle,
          color: mainColor,
          size: 12,
        ),
      ));
    }

    return Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: nameList,
      ),
    );
  }
}
