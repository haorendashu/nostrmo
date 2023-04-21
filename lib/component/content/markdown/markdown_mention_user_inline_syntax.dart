import 'dart:developer';

import 'package:markdown/markdown.dart' as md;

class MarkdownMentionUserInlineSyntax extends md.InlineSyntax {
  static const String TAG = "mentionUser";

  MarkdownMentionUserInlineSyntax() : super('nostr:npub1[a-zA-Z0-9]+');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    // var text = match.input.substring(match.start, match.end);
    var text = match[0]!;
    log(text);
    final element = md.Element.text(TAG, text);
    parser.addNode(element);

    return true;
  }
}
