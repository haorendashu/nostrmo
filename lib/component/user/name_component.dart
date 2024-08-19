import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip19/nip19.dart';
import 'package:nostrmo/component/nip05_valid_component.dart';
import 'package:nostrmo/data/metadata.dart';

import 'package:nostr_sdk/utils/string_util.dart';

class NameComponent extends StatefulWidget {
  String pubkey;

  Metadata? metadata;

  bool showNip05;

  double? fontSize;

  Color? fontColor;

  TextOverflow? textOverflow;

  int? maxLines;

  bool showName;

  NameComponent({
    required this.pubkey,
    this.metadata,
    this.showNip05 = true,
    this.fontSize,
    this.fontColor,
    this.textOverflow,
    this.maxLines = 3,
    this.showName = true,
  });

  @override
  State<StatefulWidget> createState() {
    return _NameComponent();
  }
}

class _NameComponent extends State<NameComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var textSize = themeData.textTheme.bodyMedium!.fontSize;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    Color hintColor = themeData.hintColor;
    var metadata = widget.metadata;
    String nip19Name = Nip19.encodeSimplePubKey(widget.pubkey);
    String displayName = "";
    String name = "";
    if (widget.fontColor != null) {
      hintColor = widget.fontColor!;
    }

    int nip05Status = -1;
    if (metadata != null) {
      if (StringUtil.isNotBlank(metadata.displayName)) {
        displayName = metadata.displayName!;
        if (StringUtil.isNotBlank(metadata.name)) {
          name = metadata.name!;
        }
      } else if (StringUtil.isNotBlank(metadata.name)) {
        displayName = metadata.name!;
      }

      if (StringUtil.isNotBlank(metadata.nip05)) {
        nip05Status = 1;
      }
      if (metadata.valid != null && metadata.valid! > 0) {
        nip05Status = 2;
      }
    }

    List<InlineSpan> nameList = [];

    if (StringUtil.isBlank(displayName)) {
      displayName = nip19Name;
    }
    nameList.add(TextSpan(
      text: StringUtil.breakWord(displayName),
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: widget.fontSize ?? textSize,
        color: widget.fontColor,
      ),
    ));
    if (StringUtil.isNotBlank(name) && widget.showName) {
      nameList.add(WidgetSpan(
        child: Container(
          margin: EdgeInsets.only(left: 2),
          child: Text(
            StringUtil.breakWord("@$name"),
            style: TextStyle(
              fontSize: smallTextSize,
              color: hintColor,
            ),
          ),
        ),
      ));
    }

    if (widget.showNip05) {
      var nip05Widget = Container(
        margin: const EdgeInsets.only(left: 3),
        child: Nip05ValidComponent(pubkey: widget.pubkey),
      );

      nameList.add(WidgetSpan(child: nip05Widget));
    }

    return Text.rich(
      TextSpan(children: nameList),
      maxLines: widget.maxLines,
      overflow: widget.textOverflow,
    );
  }
}
