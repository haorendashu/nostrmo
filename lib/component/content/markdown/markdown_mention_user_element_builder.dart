import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/src/ast.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/component/content/content_mention_user_component.dart';

class MarkdownMentionUserElementBuilder implements MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    print("visitElementAfter");
    var pureText = element.textContent;
    var nip19Text = pureText.replaceFirst("nostr:", "");
    var pubkey = Nip19.decode(nip19Text);

    return ContentMentionUserComponent(pubkey: pubkey);
  }

  @override
  void visitElementBefore(md.Element element) {
    print("visitElementBefore");
  }

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    print("visitText");
  }
}
