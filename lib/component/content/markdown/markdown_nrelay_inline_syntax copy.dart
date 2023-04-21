import 'dart:developer';

import 'package:markdown/markdown.dart' as md;

import 'markdown_mention_user_element_builder.dart';
import 'markdown_nrelay_element_builder.dart';

class MarkdownNrelayInlineSyntax extends md.InlineSyntax {
  MarkdownNrelayInlineSyntax() : super('nostr:nrelay[a-zA-Z0-9]+');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // var text = match.input.substring(match.start, match.end);
    var text = match[0]!;
    final element = md.Element.text(MarkdownNrelayElementBuilder.TAG, text);
    parser.addNode(element);

    return true;
  }
}
