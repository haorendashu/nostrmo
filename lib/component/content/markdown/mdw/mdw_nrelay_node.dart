import 'package:flutter/material.dart';
import 'package:markdown_widget/config/all.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:nostr_sdk/nip19/nip19_tlv.dart';

import '../../content_relay_component.dart';

class MdwNrelayNode extends SpanNode {
  md.Element element;

  MarkdownConfig config;

  WidgetVisitor visitor;

  MdwNrelayNode(this.element, this.config, this.visitor);

  @override
  InlineSpan build() {
    var pureText = element.textContent;
    var nip19Text = pureText.replaceFirst("nostr:", "");

    String? key;
    if (NIP19Tlv.isNrelay(nip19Text)) {
      var nrelay = NIP19Tlv.decodeNrelay(nip19Text);
      if (nrelay != null) {
        key = nrelay.addr;
      }
    }

    if (key != null) {
      return WidgetSpan(child: ContentRelayComponent(key));
    }

    return TextSpan(text: pureText);
  }
}
