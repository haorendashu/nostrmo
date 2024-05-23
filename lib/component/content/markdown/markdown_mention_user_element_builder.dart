import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/src/ast.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/client/nip19/nip19_tlv.dart';
import 'package:nostrmo/component/content/content_mention_user_component.dart';

class MarkdownMentionUserElementBuilder implements MarkdownElementBuilder {
  static const String TAG = "mentionUser";

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
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
      return ContentMentionUserComponent(pubkey: key);
    }
  }

  @override
  void visitElementBefore(md.Element element) {}

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {}

  @override
  Widget? visitElementAfterWithContext(BuildContext context, md.Element element,
      TextStyle? preferredStyle, TextStyle? parentStyle) {
    return null;
  }

  @override
  bool isBlockElement() {
    return false;
  }
}
