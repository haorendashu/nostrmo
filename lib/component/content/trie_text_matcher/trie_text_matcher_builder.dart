import 'package:nostrmo/component/content/trie_text_matcher/target_text_type.dart';

import 'trie_text_matcher.dart';

class TrieTextMatcherBuilder {
  static TrieTextMatcher build({Map<String, String>? emojiMap}) {
    TrieTextMatcher matcher = TrieTextMatcher();

    matcher.addNodes(TargetTextType.MD_LINK,
        [..."[".codeUnits, true, ..."](".codeUnits, true, ...")".codeUnits]);
    matcher.addNodes(TargetTextType.MD_IMAGE,
        [..."![".codeUnits, true, ..."](".codeUnits, true, ...")".codeUnits]);
    matcher.addNodes(
        TargetTextType.MD_BOLD, [..."**".codeUnits, true, ..."**".codeUnits]);
    matcher.addNodes(
        TargetTextType.MD_BOLD, [..."__".codeUnits, true, ..."__".codeUnits]);
    matcher.addNodes(
        TargetTextType.MD_ITALIC, [..."*".codeUnits, true, ..."*".codeUnits]);
    matcher.addNodes(
        TargetTextType.MD_ITALIC, [..."_".codeUnits, true, ..."_".codeUnits]);
    matcher.addNodes(
        TargetTextType.MD_DELETE, [..."~~".codeUnits, true, ..."~~".codeUnits]);
    matcher.addNodes(TargetTextType.MD_HIGHLIGHT,
        [..."==".codeUnits, true, ..."==".codeUnits]);
    matcher.addNodes(TargetTextType.MD_INLINE_CODE,
        [..."`".codeUnits, true, ..."`".codeUnits]);
    matcher.addNodes(TargetTextType.MD_BOLD_AND_ITALIC,
        [..."***".codeUnits, true, ..."***".codeUnits]);

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
