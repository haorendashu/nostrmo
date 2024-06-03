class TargetTextType {
  static const int PURE_TEXT = 1;

  // md link: [xxx](http://xxxx)
  static const int MD_LINK = 101;

  // md image: ![xxx](http://xxxx)
  static const int MD_IMAGE = 102;

  // md bold: **xxx** or __xxx__
  static const int MD_BOLD = 103;

  // md italic: *xxx* or _xxx_
  static const int MD_ITALIC = 104;

  // md delete: ~~xxx~~
  static const int MD_DELETE = 105;

  // md highlight: ==xxx==
  static const int MD_HIGHLIGHT = 106;

  // md italic: `xxx`
  static const int MD_INLINE_CODE = 107;

  // md All bold and italic: ***xx***
  static const int MD_BOLD_AND_ITALIC = 108;

  // nostr emoji: :xxx:
  static const int NOSTR_CUSTOM_EMOJI = 1010;
}
