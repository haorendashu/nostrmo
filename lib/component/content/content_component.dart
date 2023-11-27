import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:nostrmo/component/content/content_decoder.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';

import '../../client/event.dart';
import '../../client/event_kind.dart';
import '../../client/nip19/nip19.dart';
import '../../client/nip19/nip19_tlv.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/platform_util.dart';
import '../event/event_quote_component.dart';
import '../webview_router.dart';
import 'content_custom_emoji_component.dart';
import 'content_event_tag_infos.dart';
import 'content_image_component.dart';
import 'content_link_pre_component.dart';
import 'content_lnbc_component.dart';
import 'content_mention_user_component.dart';
import 'content_relay_component.dart';
import 'content_tag_component.dart';
import 'content_video_component.dart';

/// This is the new ContentComponent.
/// 1. Support image, video, link. These can config showable or replace by a str_line_component.
/// 2. Support imageListMode, true - use placeholder replaced in content and show imageList in last, false - show image in content.
/// 3. Support link, use a link preview to replace it.
/// 4. Support NIP-19, (npub, note, nprofile, nevent, nrelay, naddr). pre: (nostr:, @nostr:, @npub, @note...).
/// 5. Support Tag decode.
/// 6. Language check and auto translate.
/// 7. All inlineSpan must in the same SelectableText (Select all content one time).
/// 8. LNBC info decode (Lightning).
/// 9. Support Emoji (NIP-30)
/// 10.Show more, hide extral when the content is too long.
/// 11.Simple Markdown support. (LineStr with pre # - FontWeight blod and bigger fontSize, with pre ## - FontWeight blod and normal fontSize).
class ContentComponent extends StatefulWidget {
  String? content;
  Event? event;

  Function? textOnTap;
  bool showImage = true;
  bool showVideo = false;
  bool showLinkPreview = true;
  bool imageListMode = false;

  bool smallest;

  ContentComponent({
    this.content,
    this.event,
    this.textOnTap,
    this.showImage = true,
    this.showVideo = false,
    this.showLinkPreview = true,
    this.imageListMode = false,
    this.smallest = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _ContentComponent();
  }
}

class _ContentComponent extends State<ContentComponent> {
  // new line
  static const String NL = "\n";

  // space
  static const String SP = " ";

  // markdown h1
  static const String MD_H1 = "#";

  // markdown h2
  static const String MD_H2 = "##";

  // markdown h3
  static const String MD_H3 = "###";

  // http pre
  static const String HTTP_PRE = "http://";

  // https pre
  static const String HTTPS_PRE = "https://";

  static const String PRE_NOSTR_BASE = "nostr:";

  static const String PRE_NOSTR_AT = "@nostr:";

  static const String PRE_AT_USER = "@npub";

  static const String PRE_AT_NOTE = "@note";

  static const String PRE_USER = "npub1";

  static const String PRE_NOTE = "note1";

  static const int NPUB_LENGTH = 63;

  static const int NOTEID_LENGTH = 63;

  static const OTHER_LIGHTNING = "lightning=";

  static const LIGHTNING = "lightning:";

  static const LNBC = "lnbc";

  static List<String> LNBC_LIST = [LNBC, LIGHTNING, OTHER_LIGHTNING];

  static const LNBC_NUM_END = "1p";

  static const MAX_SHOW_LINE_NUM = 19;

  static const MAX_SHOW_LINE_NUM_REACH = 23;

  TextStyle? mdh1Style;

  TextStyle? mdh2Style;

  TextStyle? highlightStyle;

  late StringBuffer counter;

  /// this list use to hold the real text, exclude the the text had bean decoded to embed.
  List<String> textList = [];

  double smallTextSize = 13;

  double iconWidgetWidth = 14;

  Color? hintColor;

  TextSpan? translateTips;

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    smallTextSize = themeData.textTheme.bodySmall!.fontSize!;
    var fontSize = themeData.textTheme.bodyLarge!.fontSize!;
    iconWidgetWidth = fontSize + 4;
    hintColor = themeData.hintColor;
    var settingProvider = Provider.of<SettingProvider>(context);
    mdh1Style = TextStyle(
      fontSize: fontSize + 1,
      fontWeight: FontWeight.bold,
    );
    mdh2Style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
    highlightStyle = TextStyle(
      color: themeData.primaryColor,
      decoration: TextDecoration.none,
    );

    if (StringUtil.isBlank(widget.content)) {
      return Container();
    }

    counter = StringBuffer(widget.content!);
    textList.clear();

    if (targetTextMap.isNotEmpty) {
      translateTips = TextSpan(
        text: " <- ${targetLanguage!.bcpCode} | ${sourceLanguage!.bcpCode} -> ",
        style: TextStyle(
          color: hintColor,
        ),
      );
    }

    var main = decodeContent();

    // decode complete, begin to checkAndTranslate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAndTranslate();
    });

    if (widget.imageListMode &&
        settingProvider.limitNoteHeight != OpenStatus.CLOSE) {
      // imageListMode is true, means this content is in list, should limit height
      return LayoutBuilder(builder: (context, constraints) {
        TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
        textPainter.text = TextSpan(
            text: counter.toString(), style: TextStyle(fontSize: fontSize));
        textPainter.layout(maxWidth: constraints.maxWidth);
        var lineHeight = textPainter.preferredLineHeight;
        var lineNum = textPainter.height / lineHeight;

        if (lineNum > MAX_SHOW_LINE_NUM_REACH) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(),
                clipBehavior: Clip.hardEdge,
                height: lineHeight * MAX_SHOW_LINE_NUM,
                child: Wrap(
                  children: [main],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: Base.BASE_PADDING),
                  height: 30,
                  color: themeData.cardColor.withOpacity(0.85),
                  child: Text(
                    s.Show_more,
                    style: TextStyle(
                      color: themeData.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return main;
      });
    } else {
      return main;
    }
  }

  static const double CONTENT_IMAGE_LIST_HEIGHT = 90;

  TextStyle? currentTextStyle;

  ContentEventTagInfos? tagInfos;

  ContentDecoderInfo? contentDecoderInfo;

  /// decode the content to a SelectableText.
  /// 1. splite by \/n to lineStrs
  /// 2. handle lineStr
  ///     splite by `space` to strs
  /// 3. check and handle str
  ///   a. check first str and set lineTextStyle
  ///   b. check and handle str
  ///     `http://` styles: image, link, video
  ///     NIP-19 `nostr:, @nostr:, @npub, @note...` style
  ///     `#xxx` Tag style
  ///     LNBC `lnbc` `lightning:` `lightning=`
  ///     '#[number]' old style relate
  ///   c. flush buffer to string, handle emoji text, add to allSpans
  ///   d. allSpan set into simple SelectableText.rich
  Widget decodeContent() {
    if (StringUtil.isBlank(widget.content)) {
      return Container();
    }

    // decode event tag Info
    if (widget.event != null) {
      tagInfos = ContentEventTagInfos.fromEvent(widget.event!);
    } else {
      tagInfos = null;
    }
    List<InlineSpan> allList = [];
    List<String> images = [];
    var buffer = StringBuffer();
    contentDecoderInfo = decodeTest(widget.content!);

    if (targetTextMap.isNotEmpty) {
      // has bean translate
      var iconBtn = WidgetSpan(
        child: GestureDetector(
          onTap: () {
            setState(() {
              showSource = !showSource;
              if (!showSource) {
                translateTips = null;
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(
              left: MARGIN,
              right: MARGIN,
            ),
            height: iconWidgetWidth,
            width: iconWidgetWidth,
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: hintColor!),
              borderRadius: BorderRadius.circular(iconWidgetWidth / 2),
            ),
            child: Icon(
              Icons.translate,
              size: smallTextSize,
              color: hintColor,
            ),
          ),
        ),
      );
      allList.add(iconBtn);
    }

    var lineStrs = contentDecoderInfo!.strs;
    var lineLength = lineStrs.length;
    for (var i = 0; i < lineLength; i++) {
      // var lineStr = lineStrs[i];

      // this line has text, begin to handle it.
      var strs = lineStrs[i];
      var strsLength = strs.length;
      for (var j = 0; j < strsLength; j++) {
        var str = strs[j];

        if (j == 0) {
          // the first str, check simple markdown support
          if (str == MD_H1) {
            bufferToList(buffer, allList);
            currentTextStyle = mdh1Style;
            continue;
          } else if (str == MD_H2) {
            bufferToList(buffer, allList);
            currentTextStyle = mdh2Style;
            continue;
          } else {
            if (currentTextStyle != null) {
              bufferToList(buffer, allList);
            }
            currentTextStyle = null;
          }
        }

        var remain = checkAndHandleStr(str, buffer, allList, images);
        if (remain != null) {
          buffer.write(remain);
        }

        if (j < strsLength - 1) {
          buffer.write(SP);
        }
      }

      if (i < lineLength - 1) {
        bufferToList(buffer, allList);
        buffer.write(NL);
        bufferToList(buffer, allList);
      }
    }
    bufferToList(buffer, allList);

    var main = Container(
      width: !widget.smallest ? double.infinity : null,
      // padding: EdgeInsets.only(bottom: 20),
      // color: Colors.red,
      child: SelectableText.rich(
        TextSpan(
          children: allList,
        ),
        onTap: () {
          if (widget.textOnTap != null) {
            widget.textOnTap!();
          }
        },
      ),
    );
    if (widget.imageListMode &&
        (contentDecoderInfo != null && contentDecoderInfo!.imageNum > 1)) {
      List<Widget> mainList = [main];
      // showImageList in bottom
      List<Widget> imageWidgetList = [];
      var index = 0;
      for (var image in images) {
        imageWidgetList.add(SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.only(right: Base.BASE_PADDING_HALF),
            width: CONTENT_IMAGE_LIST_HEIGHT,
            height: CONTENT_IMAGE_LIST_HEIGHT,
            child: ContentImageComponent(
              imageUrl: image,
              imageList: images,
              imageIndex: index,
              height: CONTENT_IMAGE_LIST_HEIGHT,
              width: CONTENT_IMAGE_LIST_HEIGHT,
              // imageBoxFix: BoxFit.fitWidth,
            ),
          ),
        ));
        index++;
      }

      mainList.add(Container(
        height: CONTENT_IMAGE_LIST_HEIGHT,
        width: double.infinity,
        child: CustomScrollView(
          slivers: imageWidgetList,
          scrollDirection: Axis.horizontal,
        ),
      ));

      return Column(
        children: mainList,
      );
    } else {
      return main;
    }
  }

  String? checkAndHandleStr(String str, StringBuffer buffer,
      List<InlineSpan> allList, List<String> images) {
    if (str.indexOf(HTTPS_PRE) == 0 || str.indexOf(HTTP_PRE) == 0) {
      // http style, get path style
      var pathType = ContentDecoder.getPathType(str);
      if (pathType == "image") {
        images.add(str);
        if (!widget.showImage) {
          allList.add(buildLinkSpan(str));
        } else {
          if (widget.imageListMode &&
              (contentDecoderInfo != null &&
                  contentDecoderInfo!.imageNum > 1)) {
            // this content decode in list, use list mode
            var imagePlaceholder = Container(
              // margin: const EdgeInsets.only(left: 4),
              child: const Icon(
                Icons.image,
                size: 15,
              ),
            );

            bufferToList(buffer, allList, removeLastSpan: true);
            allList.add(WidgetSpan(child: imagePlaceholder));
          } else {
            // show image in content
            var imageWidget = ContentImageComponent(
              imageUrl: str,
              imageList: images,
              imageIndex: images.length - 1,
            );

            bufferToList(buffer, allList, removeLastSpan: true);
            allList.add(WidgetSpan(child: imageWidget));
            counterAddLines(fake_image_counter);
          }
        }
        return null;
      } else if (pathType == "video") {
        if (widget.showVideo && !PlatformUtil.isPC()) {
          // block
          bufferToList(buffer, allList, removeLastSpan: true);
          var vComponent = ContentVideoComponent(url: str);
          allList.add(WidgetSpan(child: vComponent));
          counterAddLines(fake_video_counter);
        } else {
          // inline
          bufferToList(buffer, allList);
          allList.add(buildLinkSpan(str));
        }
        return null;
      } else if (pathType == "link") {
        if (!widget.showLinkPreview) {
          // inline
          bufferToList(buffer, allList);
          allList.add(buildLinkSpan(str));
        } else {
          bufferToList(buffer, allList, removeLastSpan: true);
          var w = ContentLinkPreComponent(
            link: str,
          );
          allList.add(WidgetSpan(child: w));
          counterAddLines(fake_link_pre_counter);
        }
        return null;
      }
    } else if (str.indexOf(PRE_NOSTR_BASE) == 0 ||
        str.indexOf(PRE_NOSTR_AT) == 0 ||
        str.indexOf(PRE_AT_USER) == 0 ||
        str.indexOf(PRE_AT_NOTE) == 0 ||
        str.indexOf(PRE_USER) == 0 ||
        str.indexOf(PRE_NOTE) == 0) {
      var key = str.replaceFirst("@", "");
      key = str.replaceFirst(PRE_NOSTR_BASE, "");

      String? otherStr;

      if (Nip19.isPubkey(key)) {
        // inline
        // mention user
        if (key.length > NPUB_LENGTH) {
          otherStr = key.substring(NPUB_LENGTH);
          key = key.substring(0, NPUB_LENGTH);
        }
        key = Nip19.decode(key);
        bufferToList(buffer, allList);
        allList
            .add(WidgetSpan(child: ContentMentionUserComponent(pubkey: key)));

        return otherStr;
      } else if (Nip19.isNoteId(key)) {
        // block
        if (key.length > NOTEID_LENGTH) {
          otherStr = key.substring(NOTEID_LENGTH);
          key = key.substring(0, NOTEID_LENGTH);
        }
        key = Nip19.decode(key);
        bufferToList(buffer, allList, removeLastSpan: true);
        var w = EventQuoteComponent(
          id: key,
          showVideo: widget.showVideo,
        );
        allList.add(WidgetSpan(child: w));
        counterAddLines(fake_event_counter);

        return otherStr;
      } else if (NIP19Tlv.isNprofile(key)) {
        var nprofile = NIP19Tlv.decodeNprofile(key);
        if (nprofile != null) {
          // inline
          // mention user
          bufferToList(buffer, allList);
          allList.add(WidgetSpan(
              child: ContentMentionUserComponent(pubkey: nprofile.pubkey)));

          return null;
        } else {
          return str;
        }
      } else if (NIP19Tlv.isNrelay(key)) {
        var nrelay = NIP19Tlv.decodeNrelay(key);
        if (nrelay != null) {
          // inline
          bufferToList(buffer, allList);
          allList.add(WidgetSpan(child: ContentRelayComponent(nrelay.addr)));

          return null;
        } else {
          return str;
        }
      } else if (NIP19Tlv.isNevent(key)) {
        var nevent = NIP19Tlv.decodeNevent(key);
        if (nevent != null) {
          // block
          bufferToList(buffer, allList, removeLastSpan: true);
          var w = EventQuoteComponent(
            id: nevent.id,
            showVideo: widget.showVideo,
          );
          allList.add(WidgetSpan(child: w));
          counterAddLines(fake_event_counter);

          return null;
        } else {
          return str;
        }
      } else if (NIP19Tlv.isNaddr(key)) {
        var naddr = NIP19Tlv.decodeNaddr(key);
        if (naddr != null) {
          if (StringUtil.isNotBlank(naddr.id) &&
              naddr.kind == EventKind.TEXT_NOTE) {
            // block
            bufferToList(buffer, allList, removeLastSpan: true);
            var w = EventQuoteComponent(
              id: naddr.id,
              showVideo: widget.showVideo,
            );
            allList.add(WidgetSpan(child: w));
            counterAddLines(fake_event_counter);

            return null;
          } else if (StringUtil.isNotBlank(naddr.author) &&
              naddr.kind == EventKind.METADATA) {
            // inline
            bufferToList(buffer, allList);
            allList.add(WidgetSpan(
                child: ContentMentionUserComponent(pubkey: naddr.author)));

            return null;
          }
        }
      }
    } else if (str.length > 1 &&
        str.substring(0, 1) == "#" &&
        !["[", "#"].contains(str.substring(1, 2))) {
      // first char is `#`, seconde isn't `[` and `#`
      // tag
      var extralStr = "";
      var length = str.length;
      if (tagInfos != null) {
        for (var hashtagInfo in tagInfos!.tagEntryInfos) {
          var hashtag = hashtagInfo.key;
          var hashtagLength = hashtagInfo.value;
          if (str.indexOf(hashtag) == 1) {
            // dua to tagEntryInfos is sorted, so this is the match hashtag
            if (hashtagLength > 0 && length > hashtagLength) {
              // this str's length is more then hastagLength, maybe there are some extralStr.
              extralStr = str.substring(hashtagLength + 1);
              str = "#$hashtag";
            }
            break;
          }
        }
      }

      bufferToList(buffer, allList);
      allList.add(WidgetSpan(child: ContentTagComponent(tag: str)));
      if (StringUtil.isNotBlank(extralStr)) {
        return extralStr;
      }

      return null;
    } else if (str.indexOf(LNBC) == 0 ||
        str.indexOf(LIGHTNING) == 0 ||
        str.indexOf(OTHER_LIGHTNING) == 0) {
      bufferToList(buffer, allList, removeLastSpan: true);
      var w = ContentLnbcComponent(lnbc: str);
      allList.add(WidgetSpan(child: w));
      counterAddLines(fake_zap_counter);

      return null;
    } else if (widget.event != null &&
        str.length > 3 &&
        str.indexOf("#[") == 0) {
      // mention
      var endIndex = str.indexOf("]");
      var indexStr = str.substring(2, endIndex);
      var index = int.tryParse(indexStr);
      if (index != null && widget.event!.tags.length > index) {
        var tag = widget.event!.tags[index];
        if (tag.length > 1) {
          var tagType = tag[0];
          if (tagType == "e") {
            // block
            // mention event
            bufferToList(buffer, allList, removeLastSpan: true);
            var w = EventQuoteComponent(
              id: tag[1],
              showVideo: widget.showVideo,
            );
            allList.add(WidgetSpan(child: w));
            counterAddLines(fake_event_counter);

            return null;
          } else if (tagType == "p") {
            // inline
            // mention user
            bufferToList(buffer, allList);
            allList.add(
                WidgetSpan(child: ContentMentionUserComponent(pubkey: tag[1])));

            return null;
          }
        }
      }
    }
    return str;
  }

  void _removeEndBlank(List<InlineSpan> allList) {
    var length = allList.length;
    for (var i = length - 1; i >= 0; i--) {
      var span = allList[i];
      if (span is TextSpan) {
        var text = span.text;
        if (StringUtil.isNotBlank(text)) {
          text = text!.trimRight();
          if (StringUtil.isBlank(text)) {
            allList.removeLast();
          } else {
            allList[i] = TextSpan(text: text);
            return;
          }
        } else {
          allList.removeLast();
        }
      } else {
        return;
      }
    }
  }

  void bufferToList(StringBuffer buffer, List<InlineSpan> allList,
      {bool removeLastSpan = false}) {
    var text = buffer.toString();
    if (removeLastSpan) {
      // sometimes if the pre text's last chat is NL, need to remove it.
      text = text.trimRight();
      if (StringUtil.isBlank(text)) {
        _removeEndBlank(allList);
      }
    }
    buffer.clear();
    if (StringUtil.isBlank(text)) {
      return;
    }

    if (tagInfos != null && tagInfos!.emojiMap.isNotEmpty) {
      var strs = text.split(":");
      if (strs.length >= 3) {
        bool preStrIsEmoji = false;
        StringBuffer sb = StringBuffer(strs[0]);
        for (var i = 1; i < strs.length - 1; i++) {
          var emojiValue = tagInfos!.emojiMap[strs[i]];
          if (emojiValue != null) {
            // this is the emoji!!!!
            _onlyBufferToList(sb, allList);

            allList.add(WidgetSpan(
                child: ContentCustomEmojiComponent(
              imagePath: emojiValue,
            )));
            preStrIsEmoji = true;
          } else {
            // this isn't emoji, add the text to buffer
            if (!preStrIsEmoji) {
              sb.write(":");
            }
            sb.write(strs[i]);
          }
        }

        if (!preStrIsEmoji) {
          sb.write(":");
        }
        sb.write(strs.last);
        _onlyBufferToList(sb, allList);

        return;
      }
    }

    _addTextToList(text, allList);
  }

  void _onlyBufferToList(StringBuffer buffer, List<InlineSpan> allList) {
    var text = buffer.toString();
    buffer.clear();
    if (StringUtil.isNotBlank(text)) {
      _addTextToList(text, allList);
    }
  }

  void _addTextToList(String text, List<InlineSpan> allList) {
    textList.add(text);
    var targetText = targetTextMap[text];
    if (targetText == null) {
      allList.add(TextSpan(text: text, style: currentTextStyle));
    } else {
      allList.add(TextSpan(text: targetText, style: currentTextStyle));
      if (showSource && translateTips != null) {
        allList.add(translateTips!);
        allList.add(TextSpan(text: text, style: currentTextStyle));
      }
    }
  }

  TextSpan buildTapableSpan(String str, {GestureTapCallback? onTap}) {
    return TextSpan(
      text: str,
      style: highlightStyle,
      recognizer: TapGestureRecognizer()..onTap = onTap,
    );
  }

  TextSpan buildLinkSpan(String str) {
    return buildTapableSpan(str, onTap: () {
      WebViewRouter.open(context, str);
    });
  }

  static ContentDecoderInfo decodeTest(String content) {
    content = content.trim();
    var strs = content.split(NL);

    ContentDecoderInfo info = ContentDecoderInfo();
    for (var str in strs) {
      var subStrs = str.split(SP);
      info.strs.add(subStrs);
      for (var subStr in subStrs) {
        if (subStr.indexOf("http") == 0) {
          // link, image, video etc
          var pathType = ContentDecoder.getPathType(subStr);
          if (pathType == "image") {
            info.imageNum++;
          }
        }
      }
    }

    return info;
  }

  int fake_event_counter = 8;

  int fake_image_counter = 10;

  int fake_video_counter = 10;

  int fake_link_pre_counter = 6;

  int fake_zap_counter = 4;

  void counterAddLines(int lineNum) {
    for (var i = 0; i < lineNum; i++) {
      counter.write(NL);
    }
  }

  static const double MARGIN = 4;

  Map<String, String> targetTextMap = {};

  String sourceText = "";

  TranslateLanguage? sourceLanguage;

  TranslateLanguage? targetLanguage;

  bool showSource = false;

  Future<void> checkAndTranslate() async {
    var newSourceText = "";
    newSourceText = textList.join();

    if (newSourceText.length > 1000) {
      return;
    }

    if (settingProvider.openTranslate != OpenStatus.OPEN) {
      // is close
      if (targetTextMap.isNotEmpty) {
        // set targetTextMap to null
        setState(() {
          targetTextMap.clear();
        });
      }
      return;
    } else {
      // is open
      // check targetTextMap
      if (targetTextMap.isNotEmpty) {
        // targetText had bean translated
        if (targetLanguage != null &&
            targetLanguage!.bcpCode == settingProvider.translateTarget &&
            newSourceText == sourceText) {
          // and currentTargetLanguage = settingTranslate
          return;
        }
      }
    }

    var translateTarget = settingProvider.translateTarget;
    if (StringUtil.isBlank(translateTarget)) {
      return;
    }
    targetLanguage = BCP47Code.fromRawValue(translateTarget!);
    if (targetLanguage == null) {
      return;
    }

    LanguageIdentifier? languageIdentifier;
    OnDeviceTranslator? onDeviceTranslator;

    sourceText = newSourceText;

    try {
      languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
      final List<IdentifiedLanguage> possibleLanguages =
          await languageIdentifier.identifyPossibleLanguages(newSourceText);

      if (possibleLanguages.isNotEmpty) {
        var pl = possibleLanguages[0];
        if (!settingProvider.translateSourceArgsCheck(pl.languageTag)) {
          if (targetTextMap.isNotEmpty) {
            // set targetText to null
            setState(() {
              targetTextMap.clear();
            });
          }
          return;
        }

        sourceLanguage = BCP47Code.fromRawValue(pl.languageTag);
      }

      if (sourceLanguage != null) {
        onDeviceTranslator = OnDeviceTranslator(
            sourceLanguage: sourceLanguage!, targetLanguage: targetLanguage!);

        for (var text in textList) {
          if (text == NL || StringUtil.isBlank(text)) {
            continue;
          }
          var result = await onDeviceTranslator.translateText(text);
          if (StringUtil.isNotBlank(result)) {
            targetTextMap[text] = result;
          }
        }

        setState(() {});
      }
    } finally {
      if (languageIdentifier != null) {
        languageIdentifier.close();
      }
      if (onDeviceTranslator != null) {
        onDeviceTranslator.close();
      }
    }
  }
}
