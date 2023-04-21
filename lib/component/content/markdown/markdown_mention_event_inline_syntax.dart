import 'dart:developer';

import 'package:markdown/markdown.dart' as md;

import 'markdown_mention_event_element_builder.dart';

class MarkdownMentionEventInlineSyntax extends md.InlineSyntax {
  MarkdownMentionEventInlineSyntax() : super('nostr:note[a-zA-Z0-9]+');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // var text = match.input.substring(match.start, match.end);
    var text = match[0]!;
    final element =
        md.Element.text(MarkdownMentionEventElementBuilder.TAG, text);
    parser.addNode(element);

    return true;
  }
}
