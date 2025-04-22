import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/cashu/cashu_tokens.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_relation.dart';
import 'package:nostr_sdk/nip19/nip19.dart';
import 'package:nostr_sdk/nip19/nip19_tlv.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/utils/path_type_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/content/content_decoder.dart';
import 'package:nostrmo/component/content/content_music_component.dart';
import 'package:nostrmo/component/content/trie_text_matcher/target_text_type.dart';
import 'package:nostrmo/component/content/trie_text_matcher/trie_text_matcher.dart';
import 'package:nostrmo/component/content/trie_text_matcher/trie_text_matcher_builder.dart';
import 'package:nostrmo/component/music/wavlake/wavlake_track_music_info_builder.dart';
import 'package:nostrmo/consts/base64.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:nostrmo/router/group/group_search_dialog.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../consts/event_kind_type.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../event/event_quote_component.dart';
import '../groups/simple_group_metadata_component.dart';
import '../link_router_util.dart';
import '../music/blank_link_music_info_builder.dart';
import '../music/wavlake/wavlake_album_music_info_builder.dart';
import '../webview_router.dart';
import 'content_cashu_component.dart';
import 'content_custom_emoji_component.dart';
import 'content_event_tag_infos.dart';
import 'content_image_component.dart';
import 'content_link_pre_component.dart';
import 'content_lnbc_component.dart';
import 'content_mention_user_component.dart';
import 'content_relay_component.dart';
import 'content_tag_component.dart';
import 'content_video_component.dart';

const int NPUB_LENGTH = 63;

const int NOTEID_LENGTH = 63;

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

  EventRelation? eventRelation;

  ContentComponent({
    this.content,
    this.event,
    this.textOnTap,
    this.showImage = true,
    this.showVideo = false,
    this.showLinkPreview = true,
    this.imageListMode = false,
    this.smallest = false,
    this.eventRelation,
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

  // markdown h4
  static const String MD_H4 = "####";

  // markdown h5
  static const String MD_H5 = "#####";

  // markdown h6
  static const String MD_H6 = "######";

  // markdown quoting
  static const String MD_QUOTING = ">";

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

  static const String PRE_NPROFILE = "nprofile1";

  static const String PRE_NEVENT = "nevent1";

  static const String PRE_NRELAY = "nrelay1";

  static const String PRE_NADDR = "naddr1";

  static const OTHER_LIGHTNING = "lightning=";

  static const LIGHTNING = "lightning:";

  static const LNBC = "lnbc";

  static const PRE_CASHU_LINK = "cashu:";

  static const PRE_CASHU = "cashu";

  static List<String> LNBC_LIST = [LNBC, LIGHTNING, OTHER_LIGHTNING];

  static const LNBC_NUM_END = "1p";

  static const MAX_SHOW_LINE_NUM = 19;

  static const MAX_SHOW_LINE_NUM_REACH = 23;

  TextStyle? mdh1Style;

  TextStyle? mdh2Style;

  TextStyle? mdh3Style;

  TextStyle? mdh4Style;

  TextStyle boldStyle = TextStyle(
    fontWeight: FontWeight.w600,
  );

  TextStyle italicStyle = const TextStyle(
    fontStyle: FontStyle.italic,
  );

  TextStyle deleteStyle = const TextStyle(
    decoration: TextDecoration.lineThrough,
  );

  TextStyle? highlightStyle;

  TextStyle boldAndItalicStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  );

  TextStyle? tpableStyle;

  late StringBuffer counter;

  /// this list use to hold the real text, exclude the the text had bean decoded to embed.
  List<String> textList = [];

  double largetFontSize = 16;

  double fontSize = 14;

  double smallFontSize = 13;

  double iconWidgetWidth = 14;

  Color? hintColor;

  Color? codeBackgroundColor;

  TextSpan? translateTips;

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    smallFontSize = themeData.textTheme.bodySmall!.fontSize!;
    fontSize = themeData.textTheme.bodyMedium!.fontSize!;
    largetFontSize = themeData.textTheme.bodyLarge!.fontSize!;
    iconWidgetWidth = largetFontSize + 4;
    hintColor = themeData.hintColor;
    codeBackgroundColor = hintColor!.withOpacity(0.25);
    var settingProvider = Provider.of<SettingProvider>(context);
    mdh1Style = TextStyle(
      fontSize: largetFontSize + 1,
      fontWeight: FontWeight.bold,
    );
    mdh2Style = TextStyle(
      fontSize: largetFontSize,
      fontWeight: FontWeight.bold,
    );
    mdh3Style = TextStyle(
      fontSize: largetFontSize,
      fontWeight: FontWeight.w600,
    );
    mdh3Style = TextStyle(
      fontSize: largetFontSize,
      fontWeight: FontWeight.w600,
    );
    mdh4Style = TextStyle(
      fontSize: largetFontSize - 1,
      fontWeight: FontWeight.w600,
    );
    highlightStyle = TextStyle(
      backgroundColor: mainColor,
    );
    tpableStyle = TextStyle(
      color: themeData.primaryColor,
      decoration: TextDecoration.none,
    );

    if (StringUtil.isBlank(widget.content)) {
      return Container();
    }

    counter = StringBuffer();
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
    List<InlineSpan> currentList = [];
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
              size: smallFontSize,
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
      // this line has text, begin to handle it.
      var strs = lineStrs[i];
      var strsLength = strs.length;
      bool lineBegin = true;
      for (var j = 0; j < strsLength; j++) {
        var str = strs[j];
        str = str.trim();

        if (lineBegin) {
          // the first str, check simple markdown support
          if (str == MD_H1) {
            closeLine(buffer, currentList, allList, images);
            currentTextStyle = mdh1Style;
            continue;
          } else if (str == MD_H2) {
            closeLine(buffer, currentList, allList, images);
            currentTextStyle = mdh2Style;
            continue;
          } else if (str == MD_H3) {
            closeLine(buffer, currentList, allList, images);
            currentTextStyle = mdh3Style;
            continue;
          } else if (str == MD_H4) {
            closeLine(buffer, currentList, allList, images);
            currentTextStyle = mdh4Style;
            continue;
          } else if (str == MD_H5) {
            closeLine(buffer, currentList, allList, images);
            currentTextStyle = mdh4Style;
            continue;
          } else if (str == MD_H6) {
            closeLine(buffer, currentList, allList, images);
            currentTextStyle = mdh4Style;
            continue;
          } else if (str == MD_QUOTING) {
            if (j == 0) {
              closeLine(buffer, currentList, allList, images);
              currentTextStyle = null;
            } else {
              bufferToList(buffer, currentList, images);
            }
            currentList.add(WidgetSpan(
                child: Container(
              width: 4,
              height: fontSize + 5.5,
              color: hintColor,
              margin: const EdgeInsets.only(right: Base.BASE_PADDING),
            )));
            continue;
          } else if (j == 0 && str.startsWith("```")) {
            // a new line start with ```, this is a block code
            // try to find the end ```
            int? endI;
            for (var tempI = i + 1; tempI < lineLength; tempI++) {
              var strs = lineStrs[tempI];
              if (strs.isNotEmpty && strs.first.startsWith("```")) {
                // find the end ``` !!!
                endI = tempI;
                break;
              }
            }
            if (endI != null) {
              List<String> codeLines = [];
              for (var tempI = i + 1; tempI < endI; tempI++) {
                var strs = lineStrs[tempI];
                codeLines.add(strs.join(SP));
              }

              var codeText = codeLines.join(NL);
              currentList.add(
                WidgetSpan(
                  child: Container(
                    padding: const EdgeInsets.all(Base.BASE_PADDING),
                    width: double.infinity,
                    decoration: BoxDecoration(color: codeBackgroundColor),
                    child: SelectableText(codeText),
                  ),
                ),
              );

              i = endI;
              break;
            }
          } else if (j == 0 &&
              (str.startsWith("---") ||
                  (str.startsWith("***") && strsLength == 1)) &&
              (str.replaceAll("-", "") == "" ||
                  str.replaceAll("*", "") == "")) {
            // is line start
            // str is start with --- or ***
            // str in only * or -
            bufferToList(buffer, currentList, images);
            currentList.add(const WidgetSpan(child: Divider()));
            if (j == strsLength - 1 && i + 1 < lineLength) {
              // current line is over and has next line, check if next line is NL only
              var nextStrs = lineStrs[i + 1];
              if (nextStrs.length == 1 && nextStrs[0] == "") {
                // next line is NL only, add this Widget span can help the display don't ignore the NLs after Divider
                currentList.add(const WidgetSpan(child: Text("")));
                // ignore the next NL
                i++;
              }
            }
            continue;
          } else if (j == 0) {
            if (currentTextStyle != null) {
              closeLine(buffer, currentList, allList, images);
            }
            currentTextStyle = null;
          }
        }

        if (str != "") {
          lineBegin = false;
        }

        var remain = checkAndHandleStr(str, buffer, currentList, images);
        if (remain != null) {
          buffer.write(remain);
        }

        if (j < strsLength - 1) {
          buffer.write(SP);
        }
      }

      if (i < lineLength - 1) {
        bufferToList(buffer, currentList, images);
        buffer.write(NL);
        bufferToList(buffer, currentList, images);
      }
    }
    closeLine(buffer, currentList, allList, images);

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
    if (widget.showImage &&
        widget.imageListMode &&
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
              fileMetadata: getFileMetadata(image),
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

  void closeLine(StringBuffer buffer, List<InlineSpan> currentList,
      List<InlineSpan> allList, List<String> images,
      {bool removeLastSpan = false}) {
    bufferToList(buffer, currentList, images, removeLastSpan: removeLastSpan);

    if (currentList.isNotEmpty) {
      allList.addAll(currentList);
    }

    currentList.clear();
  }

  String? checkAndHandleStr(String str, StringBuffer buffer,
      List<InlineSpan> currentList, List<String> images) {
    if (str.indexOf(HTTPS_PRE) == 0 ||
        str.indexOf(HTTP_PRE) == 0 ||
        str.indexOf(BASE64.PREFIX) == 0) {
      // http style, get path style
      var pathType = PathTypeUtil.getPathType(str);
      if (pathType == "image") {
        images.add(str);
        if (!widget.showImage) {
          currentList.add(buildLinkSpan(str));
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

            bufferToList(buffer, currentList, images, removeLastSpan: true);
            currentList.add(WidgetSpan(child: imagePlaceholder));
          } else {
            // show image in content
            var imageWidget = ContentImageComponent(
              imageUrl: str,
              imageList: images,
              imageIndex: images.length - 1,
              fileMetadata: getFileMetadata(str),
            );

            bufferToList(buffer, currentList, images, removeLastSpan: true);
            currentList.add(WidgetSpan(child: imageWidget));
            counterAddLines(fake_image_counter);
          }
        }
        return null;
      } else if (pathType == "video") {
        if (widget.showVideo) {
          // block
          bufferToList(buffer, currentList, images, removeLastSpan: true);
          var vComponent = ContentVideoComponent(url: str);
          currentList.add(WidgetSpan(child: vComponent));
          counterAddLines(fake_video_counter);
        } else {
          // inline
          bufferToList(buffer, currentList, images);
          currentList.add(buildLinkSpan(str));
        }
        return null;
      } else if (pathType == "link") {
        // TODO make a music builder list
        if (wavlakeTrackMusicInfoBuilder.check(str)) {
          // check if it is wavlake track link
          String? eventId;
          if (widget.event != null) {
            eventId = widget.event!.id;
          }
          bufferToList(buffer, currentList, images, removeLastSpan: true);
          var w =
              ContentMusicComponent(eventId, str, wavlakeTrackMusicInfoBuilder);
          currentList.add(WidgetSpan(child: w));
          counterAddLines(fake_music_counter);

          return null;
        }
        if (wavlakeAlbumMusicInfoBuilder.check(str)) {
          // check if it is wavlake track link
          String? eventId;
          if (widget.event != null) {
            eventId = widget.event!.id;
          }
          bufferToList(buffer, currentList, images, removeLastSpan: true);
          var w =
              ContentMusicComponent(eventId, str, wavlakeAlbumMusicInfoBuilder);
          currentList.add(WidgetSpan(child: w));
          counterAddLines(fake_music_counter);

          return null;
        }

        if (!widget.showLinkPreview) {
          // inline
          bufferToList(buffer, currentList, images);
          currentList.add(buildLinkSpan(str));
        } else {
          bufferToList(buffer, currentList, images, removeLastSpan: true);
          var w = ContentLinkPreComponent(
            link: str,
          );
          currentList.add(WidgetSpan(child: w));
          counterAddLines(fake_link_pre_counter);
        }

        return null;
      } else if (pathType == "audio") {
        String? eventId;
        if (widget.event != null) {
          eventId = widget.event!.id;
        }
        bufferToList(buffer, currentList, images, removeLastSpan: true);
        var w = ContentMusicComponent(eventId, str, blankLinkMusicInfoBuilder);
        currentList.add(WidgetSpan(child: w));
        counterAddLines(fake_music_counter);

        return null;
      }
    } else if (str.indexOf(PRE_NOSTR_BASE) == 0 ||
        str.indexOf(PRE_NOSTR_AT) == 0 ||
        str.indexOf(PRE_AT_USER) == 0 ||
        str.indexOf(PRE_AT_NOTE) == 0 ||
        str.indexOf(PRE_USER) == 0 ||
        str.indexOf(PRE_NOTE) == 0 ||
        str.indexOf(PRE_NADDR) == 0 ||
        str.indexOf(PRE_NEVENT) == 0 ||
        str.indexOf(PRE_NPROFILE) == 0 ||
        str.indexOf(PRE_NRELAY) == 0) {
      var key = str.replaceFirst("@", "");
      key = key.replaceFirst(PRE_NOSTR_BASE, "");

      String? otherStr;

      if (Nip19.isPubkey(key)) {
        // inline
        // mention user
        if (key.length > NPUB_LENGTH) {
          otherStr = key.substring(NPUB_LENGTH);
          key = key.substring(0, NPUB_LENGTH);
        }
        key = Nip19.decode(key);
        bufferToList(buffer, currentList, images);
        currentList
            .add(WidgetSpan(child: ContentMentionUserComponent(pubkey: key)));

        return otherStr;
      } else if (Nip19.isNoteId(key)) {
        // block
        if (key.length > NOTEID_LENGTH) {
          otherStr = key.substring(NOTEID_LENGTH);
          key = key.substring(0, NOTEID_LENGTH);
        }
        key = Nip19.decode(key);
        bufferToList(buffer, currentList, images, removeLastSpan: true);
        var w = EventQuoteComponent(
          id: key,
          showVideo: widget.showVideo,
        );
        currentList.add(WidgetSpan(child: w));
        counterAddLines(fake_event_counter);

        return otherStr;
      } else if (NIP19Tlv.isNprofile(key)) {
        var index = Nip19.checkBech32End(key);
        if (index != null) {
          otherStr = key.substring(index);
          key = key.substring(0, index);
        }

        var nprofile = NIP19Tlv.decodeNprofile(key);
        if (nprofile != null) {
          // inline
          // mention user
          bufferToList(buffer, currentList, images);
          currentList.add(WidgetSpan(
              child: ContentMentionUserComponent(pubkey: nprofile.pubkey)));

          return otherStr;
        } else {
          return str;
        }
      } else if (NIP19Tlv.isNrelay(key)) {
        var index = Nip19.checkBech32End(key);
        if (index != null) {
          otherStr = key.substring(index);
          key = key.substring(0, index);
        }

        var nrelay = NIP19Tlv.decodeNrelay(key);
        if (nrelay != null) {
          // inline
          bufferToList(buffer, currentList, images);
          currentList
              .add(WidgetSpan(child: ContentRelayComponent(nrelay.addr)));

          return otherStr;
        } else {
          return str;
        }
      } else if (NIP19Tlv.isNevent(key)) {
        var index = Nip19.checkBech32End(key);
        if (index != null) {
          otherStr = key.substring(index);
          key = key.substring(0, index);
        }

        var nevent = NIP19Tlv.decodeNevent(key);
        if (nevent != null &&
            (nevent.kind == null ||
                EventKindType.SUPPORTED_EVENTS.contains(nevent.kind))) {
          // block
          bufferToList(buffer, currentList, images, removeLastSpan: true);
          var w = EventQuoteComponent(
            id: nevent.id,
            eventRelayAddr: nevent.relays != null && nevent.relays!.isNotEmpty
                ? nevent.relays![0]
                : null,
            showVideo: widget.showVideo,
          );
          currentList.add(WidgetSpan(child: w));
          counterAddLines(fake_event_counter);

          return otherStr;
        } else {
          return str;
        }
      } else if (NIP19Tlv.isNaddr(key)) {
        var index = Nip19.checkBech32End(key);
        if (index != null) {
          otherStr = key.substring(index);
          key = key.substring(0, index);
        }

        var naddr = NIP19Tlv.decodeNaddr(key);
        print(naddr.toString());
        if (naddr != null) {
          String? eventRelayAddr =
              naddr.relays != null && naddr.relays!.isNotEmpty
                  ? naddr.relays![0]
                  : null;
          if (StringUtil.isBlank(eventRelayAddr) && widget.event != null) {
            var ownerReadRelays =
                metadataProvider.getExtralRelays(widget.event!.pubkey, false);
            if (ownerReadRelays.isNotEmpty) {
              eventRelayAddr = ownerReadRelays.first;
            }
          }

          if (StringUtil.isNotBlank(naddr.author) &&
              naddr.kind == EventKind.METADATA) {
            // inline
            bufferToList(buffer, currentList, images);
            currentList.add(WidgetSpan(
                child: ContentMentionUserComponent(pubkey: naddr.author)));

            return otherStr;
          } else if (StringUtil.isNotBlank(naddr.id) &&
              EventKindType.SUPPORTED_EVENTS.contains(naddr.kind)) {
            // block
            String? id = naddr.id;
            AId? aid;
            if (id.length > 64 && StringUtil.isNotBlank(naddr.author)) {
              aid =
                  AId(kind: naddr.kind, pubkey: naddr.author, title: naddr.id);
              id = null;
            }

            bufferToList(buffer, currentList, images, removeLastSpan: true);
            var w = EventQuoteComponent(
              id: id,
              aId: aid,
              eventRelayAddr: eventRelayAddr,
              showVideo: widget.showVideo,
            );
            currentList.add(WidgetSpan(child: w));
            counterAddLines(fake_event_counter);

            return otherStr;
          } else if (naddr.kind == EventKind.LIVE_EVENT) {
            bufferToList(buffer, currentList, images, removeLastSpan: true);
            var w = ContentLinkPreComponent(
              link: "https://zap.stream/$key",
            );
            currentList.add(WidgetSpan(child: w));
            counterAddLines(fake_link_pre_counter);

            return otherStr;
          } else if (naddr.kind != null &&
              StringUtil.isNotBlank(naddr.author) &&
              StringUtil.isNotBlank(naddr.id) &&
              (naddr.kind == EventKind.FOLLOW_SETS)) {
            // block
            AId aid =
                AId(kind: naddr.kind, pubkey: naddr.author, title: naddr.id);

            var w = EventQuoteComponent(
              id: null,
              aId: aid,
              eventRelayAddr: eventRelayAddr,
              showVideo: widget.showVideo,
              relays: naddr.relays,
            );
            currentList.add(WidgetSpan(child: w));
            counterAddLines(1);

            return otherStr;
          } else if (naddr.kind == EventKind.GROUP_METADATA &&
              StringUtil.isNotBlank(naddr.id) &&
              naddr.relays != null &&
              naddr.relays!.isNotEmpty) {
            var groupIdentifier =
                GroupIdentifier(naddr.relays!.first, naddr.id);
            var w = SimpleGroupMetadataComponent(groupIdentifier);

            currentList.add(WidgetSpan(child: w));
            counterAddLines(fake_event_counter);

            return otherStr;
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

      bufferToList(buffer, currentList, images);
      currentList.add(WidgetSpan(
        alignment: PlaceholderAlignment.bottom,
        child: ContentTagComponent(tag: str),
      ));
      if (StringUtil.isNotBlank(extralStr)) {
        return extralStr;
      }

      return null;
    } else if (str.indexOf(LNBC) == 0 ||
        str.indexOf(LIGHTNING) == 0 ||
        str.indexOf(OTHER_LIGHTNING) == 0) {
      bufferToList(buffer, currentList, images, removeLastSpan: true);
      var w = ContentLnbcComponent(lnbc: str);
      currentList.add(WidgetSpan(child: w));
      counterAddLines(fake_zap_counter);

      return null;
    } else if (str.length > 20 && str.indexOf(PRE_CASHU) == 0) {
      var cashuStr = str.replaceFirst(PRE_CASHU_LINK, str);
      var cashuTokens = Tokens.load(cashuStr);
      if (cashuTokens != null) {
        // decode success
        bufferToList(buffer, currentList, images, removeLastSpan: true);
        var w = ContentCashuComponent(
          tokens: cashuTokens,
          cashuStr: cashuStr,
        );
        currentList.add(WidgetSpan(child: w));
        counterAddLines(fake_zap_counter);
        return null;
      }
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
          String? relayAddr;
          if (tag.length > 2) {
            relayAddr = tag[2];
          }
          if (tagType == "e") {
            // block
            // mention event
            bufferToList(buffer, currentList, images, removeLastSpan: true);
            var w = EventQuoteComponent(
              id: tag[1],
              eventRelayAddr: relayAddr,
              showVideo: widget.showVideo,
            );
            currentList.add(WidgetSpan(child: w));
            counterAddLines(fake_event_counter);

            return null;
          } else if (tagType == "p") {
            // inline
            // mention user
            bufferToList(buffer, currentList, images);
            currentList.add(
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

  void bufferToList(
      StringBuffer buffer, List<InlineSpan> currentList, List<String> images,
      {bool removeLastSpan = false}) {
    var text = buffer.toString();
    if (removeLastSpan) {
      // sometimes if the pre text's last chat is NL, need to remove it.
      text = text.trimRight();
      if (StringUtil.isBlank(text)) {
        _removeEndBlank(currentList);
      }
    }
    buffer.clear();
    if (StringUtil.isBlank(text)) {
      return;
    }

    TrieTextMatcher matcher;
    if (tagInfos != null && tagInfos!.emojiMap.isNotEmpty) {
      matcher = TrieTextMatcherBuilder.build(emojiMap: tagInfos!.emojiMap);
    } else {
      matcher = defaultTrieTextMatcher;
    }

    var codeUnits = text.codeUnits;
    var result = matcher.check(codeUnits);

    for (var item in result.items) {
      if (item.textType == TargetTextType.PURE_TEXT) {
        _addTextToList(
            codeUnitsToString(codeUnits, item.start, item.end), currentList);
      } else if (item.args.isNotEmpty) {
        var firstArg = item.args[0];

        // not pure text and args not empty
        if (item.textType == TargetTextType.MD_LINK) {
          if (item.args.length > 1) {
            var linkArg = item.args[1];
            if (linkArg.textType == TargetTextType.PURE_TEXT) {
              var str =
                  codeUnitsToString(codeUnits, linkArg.start, linkArg.end);
              var pathType = PathTypeUtil.getPathType(str);

              if (pathType != "link" || !widget.showLinkPreview) {
                // inline
                currentList.add(buildLinkSpan(str));
              } else {
                var w = ContentLinkPreComponent(
                  link: str,
                );
                currentList.add(WidgetSpan(child: w));
                counterAddLines(fake_link_pre_counter);
              }
            }
          }
        } else if (item.textType == TargetTextType.MD_IMAGE) {
          var linkArg = item.args.last;
          if (linkArg.textType == TargetTextType.PURE_TEXT) {
            var str = codeUnitsToString(codeUnits, linkArg.start, linkArg.end);
            images.add(str);
            if (!widget.showImage) {
              currentList.add(buildLinkSpan(str));
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

                currentList.add(WidgetSpan(child: imagePlaceholder));
              } else {
                // show image in content
                var imageWidget = ContentImageComponent(
                  imageUrl: str,
                  imageList: images,
                  imageIndex: images.length - 1,
                  fileMetadata: getFileMetadata(str),
                );

                currentList.add(WidgetSpan(child: imageWidget));
                counterAddLines(fake_image_counter);
              }
            }
          }
        } else if (item.textType == TargetTextType.MD_BOLD) {
          var str = codeUnitsToString(codeUnits, firstArg.start, firstArg.end);
          _addTextToList(str, currentList, textStyle: boldStyle);
        } else if (item.textType == TargetTextType.MD_ITALIC) {
          var str = codeUnitsToString(codeUnits, firstArg.start, firstArg.end);
          _addTextToList(str, currentList, textStyle: italicStyle);
        } else if (item.textType == TargetTextType.MD_DELETE) {
          var str = codeUnitsToString(codeUnits, firstArg.start, firstArg.end);
          _addTextToList(str, currentList, textStyle: deleteStyle);
        } else if (item.textType == TargetTextType.MD_HIGHLIGHT) {
          var str = codeUnitsToString(codeUnits, firstArg.start, firstArg.end);
          _addTextToList(str, currentList, textStyle: highlightStyle);
        } else if (item.textType == TargetTextType.MD_INLINE_CODE) {
          var str = codeUnitsToString(codeUnits, firstArg.start, firstArg.end);
          currentList.add(TextSpan(
            text: str,
            style: TextStyle(
              backgroundColor: codeBackgroundColor,
            ),
          ));
        } else if (item.textType == TargetTextType.MD_BOLD_AND_ITALIC) {
          var str = codeUnitsToString(codeUnits, firstArg.start, firstArg.end);
          _addTextToList(str, currentList, textStyle: boldAndItalicStyle);
        }
      } else if (item.textType == TargetTextType.NOSTR_CUSTOM_EMOJI) {
        var emojiKey =
            codeUnitsToString(codeUnits, item.start + 1, item.end - 1);
        var emojiValue = tagInfos!.emojiMap[emojiKey];
        if (emojiValue != null) {
          currentList.add(WidgetSpan(
              child: ContentCustomEmojiComponent(
            imagePath: emojiValue,
          )));
        }
      }
    }

    return;
    // _addTextToList(text, currentList);
  }

  String codeUnitsToString(List<int> codeUnits, int start, int end) {
    var subList = codeUnits.sublist(start, end + 1);
    return String.fromCharCodes(subList);
  }

  void _onlyBufferToList(StringBuffer buffer, List<InlineSpan> allList) {
    var text = buffer.toString();
    buffer.clear();
    if (StringUtil.isNotBlank(text)) {
      _addTextToList(text, allList);
    }
  }

  void _addTextToList(String text, List<InlineSpan> allList,
      {TextStyle? textStyle}) {
    if (currentTextStyle != null) {
      if (textStyle == null) {
        textStyle = currentTextStyle;
      } else {
        textStyle = currentTextStyle!.merge(textStyle);
      }
    }

    counter.write(text);

    textList.add(text);
    var targetText = targetTextMap[text];
    if (targetText == null) {
      allList.add(TextSpan(text: text, style: textStyle));
    } else {
      allList.add(TextSpan(text: targetText, style: textStyle));
      if (showSource && translateTips != null) {
        allList.add(translateTips!);
        allList.add(TextSpan(text: text, style: textStyle));
      }
    }
  }

  TextSpan buildTapableSpan(String str, {GestureTapCallback? onTap}) {
    return TextSpan(
      text: str,
      style: tpableStyle,
      recognizer: TapGestureRecognizer()..onTap = onTap,
    );
  }

  TextSpan buildLinkSpan(String str) {
    return buildTapableSpan(str, onTap: () {
      LinkRouterUtil.router(context, str);
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
          var pathType = PathTypeUtil.getPathType(subStr);
          if (pathType == "image") {
            info.imageNum++;
          }
        }
      }
    }

    return info;
  }

  int fake_event_counter = 10;

  int fake_image_counter = 11;

  int fake_video_counter = 11;

  int fake_link_pre_counter = 7;

  int fake_music_counter = 3;

  int fake_zap_counter = 6;

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

  getFileMetadata(String image) {
    if (widget.eventRelation != null) {
      return widget.eventRelation!.fileMetadatas[image];
    }
  }
}
