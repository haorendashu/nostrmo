import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip07/kind_descriptions.dart';
import 'package:nostrmo/client/nip07/nip07_methods.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_util.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../util/router_util.dart';

class NIP07Dialog extends StatefulWidget {
  String method;

  String? content;

  NIP07Dialog({
    required this.method,
    this.content,
  });

  static Future<bool?> show(BuildContext context, String method,
      {String? content}) async {
    return await showDialog<bool>(
      context: context,
      builder: (_context) {
        return NIP07Dialog(
          method: method,
          content: content,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _NIP07Dialog();
  }
}

class _NIP07Dialog extends State<NIP07Dialog> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    Color cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    var s = S.of(context);

    List<Widget> list = [];
    list.add(Container(
      child: Text(
        "NIP-07 ${s.Comfirm}",
        style: TextStyle(
          fontSize: titleFontSize! + 4,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    list.add(Divider());

    list.add(Container(
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: Row(
        children: [
          Text("${s.Method}:  "),
          Text(widget.method),
        ],
      ),
    ));

    String methodDesc = s.NIP07_getPublicKey;
    if (widget.method == NIP07Methods.getRelays) {
      methodDesc = s.NIP07_getRelays;
    } else if (widget.method == NIP07Methods.nip04_encrypt) {
      methodDesc = s.NIP07_encrypt;
    } else if (widget.method == NIP07Methods.nip04_decrypt) {
      methodDesc = s.NIP07_decrypt;
    } else if (widget.method == NIP07Methods.signEvent) {
      methodDesc = s.NIP07_signEvent;
      try {
        if (StringUtil.isNotBlank(widget.content)) {
          var jsonObj = jsonDecode(widget.content!);
          var eventKind = jsonObj["kind"];
          var kindDesc = KindDescriptions.getDes(eventKind);
          methodDesc += ": $kindDesc";
        }
      } catch (e) {}
    }
    list.add(Container(
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: Row(
        children: [
          Text(methodDesc),
        ],
      ),
    ));

    if (StringUtil.isNotBlank(widget.content)) {
      list.add(Container(
        child: Text("${s.Content}:"),
      ));
      list.add(Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
        decoration: BoxDecoration(
          color: hintColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        margin: const EdgeInsets.only(
          bottom: Base.BASE_PADDING_HALF,
          top: Base.BASE_PADDING_HALF,
        ),
        child: SelectableText(widget.content!),
      ));
    }

    list.add(Container(
      margin: EdgeInsets.only(top: Base.BASE_PADDING_HALF),
      child: Row(children: [
        Expanded(
            child: InkWell(
          onTap: () {
            RouterUtil.back(context, false);
          },
          child: Container(
            height: 36,
            color: hintColor.withOpacity(0.3),
            alignment: Alignment.center,
            child: Text(
              s.Cancel,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )),
        Container(
          width: Base.BASE_PADDING,
        ),
        Expanded(
            child: InkWell(
          onTap: () {
            RouterUtil.back(context, true);
          },
          child: Container(
            height: 36,
            color: hintColor.withOpacity(0.3),
            alignment: Alignment.center,
            child: Text(
              s.Comfirm,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )),
      ]),
    ));

    var main = Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(maxHeight: mediaDataCache.size.height * 0.85),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: list,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }
}
