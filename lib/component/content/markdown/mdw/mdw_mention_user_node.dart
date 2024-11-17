import 'package:flutter/material.dart';
import 'package:markdown_widget/config/all.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:nostr_sdk/nip19/nip19.dart';
import 'package:nostr_sdk/nip19/nip19_tlv.dart';

import '../../content_mention_user_component.dart';

class MdwMentionUserNode extends SpanNode {
  md.Element element;

  MarkdownConfig config;

  WidgetVisitor visitor;

  MdwMentionUserNode(this.element, this.config, this.visitor);

  @override
  InlineSpan build() {
    var pureText = element.textContent;
    var nip19Text = pureText.replaceFirst("nostr:", "");

    String? key;
    if (Nip19.isPubkey(nip19Text)) {
      key = Nip19.decode(nip19Text);
    } else if (NIP19Tlv.isNprofile(nip19Text)) {
      var nprofile = NIP19Tlv.decodeNprofile(nip19Text);
      if (nprofile != null) {
        key = nprofile.pubkey;
      }
    }

    if (key != null) {
      return WidgetSpan(
        child: ContentMentionUserComponent(pubkey: key),
      );
    }

    return TextSpan(text: pureText);
  }
}
