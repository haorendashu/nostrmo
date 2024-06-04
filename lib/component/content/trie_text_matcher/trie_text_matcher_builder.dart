import 'package:nostrmo/component/content/trie_text_matcher/target_text_type.dart';

import 'trie_text_matcher.dart';

class TrieTextMatcherBuilder {
  static TrieTextMatcher build({Map<String, String>? emojiMap}) {
    TrieTextMatcher matcher = TrieTextMatcher();

    matcher.addNodes(TargetTextType.MD_LINK,
        [..."[".codeUnits, -1, ..."](".codeUnits, -1, ...")".codeUnits]);
    matcher.addNodes(TargetTextType.MD_IMAGE,
        [..."![".codeUnits, -1, ..."](".codeUnits, -1, ...")".codeUnits]);
    matcher.addNodes(
        TargetTextType.MD_IMAGE, [..."![](".codeUnits, -1, ...")".codeUnits]);
    matcher.addNodes(
        TargetTextType.MD_BOLD, [..."**".codeUnits, -1, ..."**".codeUnits]);
    matcher.addNodes(
        TargetTextType.MD_BOLD, [..."__".codeUnits, -1, ..."__".codeUnits]);
    matcher.addNodes(
        TargetTextType.MD_ITALIC, [..."*".codeUnits, -1, ..."*".codeUnits]);
    matcher.addNodes(
        TargetTextType.MD_ITALIC, [..."_".codeUnits, -1, ..."_".codeUnits]);
    matcher.addNodes(
        TargetTextType.MD_DELETE, [..."~~".codeUnits, -1, ..."~~".codeUnits]);
    matcher.addNodes(TargetTextType.MD_HIGHLIGHT,
        [..."==".codeUnits, -1, ..."==".codeUnits]);
    matcher.addNodes(TargetTextType.MD_INLINE_CODE,
        [..."`".codeUnits, -1, ..."`".codeUnits]);
    matcher.addNodes(TargetTextType.MD_BOLD_AND_ITALIC,
        [..."***".codeUnits, -1, ..."***".codeUnits]);

    if (emojiMap != null && emojiMap.isNotEmpty) {
      for (var emojiKey in emojiMap.keys) {
        matcher.addNodes(
            TargetTextType.NOSTR_CUSTOM_EMOJI, ":$emojiKey:".codeUnits,
            allowNoArg: true);
      }
    }

    return matcher;
  }
}
