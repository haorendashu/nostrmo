import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:nostrmo/component/content/content_event_tag_infos.dart';
import 'package:string_validator/string_validator.dart';

import '../../client/event.dart';
import '../../client/nip19/nip19.dart';
import '../../client/nip19/nip19_tlv.dart';
import '../../consts/base.dart';
import '../../main.dart';
import '../../util/platform_util.dart';
import '../../util/string_util.dart';
import '../event/event_quote_component.dart';
import '../translate/line_translate_component.dart';
import 'content_image_component.dart';
import 'content_link_component.dart';
import 'content_link_pre_component.dart';
import 'content_lnbc_component.dart';
import 'content_mention_user_component.dart';
import 'content_relay_component.dart';
import 'content_str_link_component.dart';
import 'content_tag_component.dart';
import 'content_video_component.dart';
import 'content_youtube_component.dart';

class ContentDecoder {
  static const OTHER_LIGHTNING = "lightning=";

  static const LIGHTNING = "lightning:";

  static const LNBC = "lnbc";

  static const NOTE_REFERENCES = "nostr:";

  static const NOTE_REFERENCES_AT = "@nostr:";

  static const MENTION_USER = "@npub";

  static const MENTION_NOTE = "@note";

  static const LNBC_NUM_END = "1p";

  static String _addToHandledStr(String handledStr, String subStr) {
    if (StringUtil.isBlank(handledStr)) {
      return subStr;
    } else {
      return "$handledStr $subStr";
    }
  }

  static String _closeHandledStr(String handledStr, List<dynamic> inlines) {
    if (StringUtil.isNotBlank(handledStr)) {
      // inlines.add(Text(handledStr));
      inlines.add(handledStr);
    }
    return "";
  }

  static void _closeInlines(List<dynamic> inlines, List<Widget> list,
      {Function? textOnTap}) {
    if (inlines.isNotEmpty) {
      if (inlines.length == 1) {
        if (inlines[0] is String) {
          // list.add(TextTranslateComponent(
          //   inlines[0],
          //   textOnTap: textOnTap,
          // ));
          list.add(LineTranslateComponent(
            []..add(inlines[0]),
            textOnTap: textOnTap,
          ));
        } else {
          list.add(inlines[0]);
        }
      } else {
        // List<InlineSpan> spans = [];
        // for (var inline in inlines) {
        //   if (inline is String) {
        //     spans.add(WidgetSpan(
        //         child: TextTranslateComponent(
        //       inline + " ",
        //       textOnTap: textOnTap,
        //     )));
        //   } else {
        //     spans.add(WidgetSpan(child: inline));
        //   }
        // }
        // list.add(Text.rich(TextSpan(children: spans)));

        list.add(LineTranslateComponent(
          []..addAll(inlines),
          textOnTap: textOnTap,
        ));
      }
      inlines.clear();
    }
  }

  static ContentDecoderInfo _decodeTest(String content) {
    content = content.trim();
    content = content.replaceAll("\r\n", "\n");
    content = content.replaceAll("\n\n", "\n");
    var strs = content.split("\n");

    ContentDecoderInfo info = ContentDecoderInfo();
    for (var str in strs) {
      List<dynamic> inlines = [];
      String handledStr = "";

      var subStrs = str.split(" ");
      info.strs.add(subStrs);
      for (var subStr in subStrs) {
        if (subStr.indexOf("http") == 0) {
          // link, image, video etc
          var pathType = getPathType(subStr);
          if (pathType == "image") {
            info.imageNum++;
          }
        }
      }
    }

    return info;
  }

  static List<Widget> decode(
    BuildContext context,
    String? content,
    Event? event, {
    Function? textOnTap,
    bool showImage = true,
    bool showVideo = false,
    bool showLinkPreview = true,
    bool imageListMode = false,
  }) {
    if (StringUtil.isBlank(content) && event != null) {
      content = event.content;
    }
    List<Widget> list = [];
    List<String> imageList = [];

    var decodeInfo = _decodeTest(content!);
    ContentEventTagInfos? tagInfos;
    if (event != null) {
      tagInfos = ContentEventTagInfos.fromEvent(event);
    }

    for (var subStrs in decodeInfo.strs) {
      List<dynamic> inlines = [];
      String handledStr = "";

      ///
      /// 1、str: add to handledStr
      /// 2、inline: put handledStr to inlines, put currentInline to inlines, new a new handledStr
      /// 3、block: put handledStr to inlines, put inlines to list as a line, put block to list as a line, new a new handledStr
      /// 4、if handledStr not empty, put to inlines, put inlines to list as a line
      ///
      for (var subStr in subStrs) {
        if (subStr.indexOf("http") == 0) {
          // link, image, video etc
          var pathType = getPathType(subStr);
          if (pathType == "image") {
            if (showImage) {
              imageList.add(subStr);
              if (imageListMode && decodeInfo.imageNum > 1) {
                // inline
                handledStr = handledStr.trim();
                var imagePlaceholder = Container(
                  margin: const EdgeInsets.only(left: 4),
                  child: const Icon(
                    Icons.image,
                    size: 15,
                  ),
                );
                if (StringUtil.isBlank(handledStr) && inlines.isEmpty) {
                  // add to pre line
                  var listLength = list.length;
                  if (listLength > 0) {
                    var lastListWidget = list[listLength - 1];
                    List<InlineSpan> spans = [];
                    if (lastListWidget is SelectableText) {
                      if (lastListWidget.data != null) {
                        spans.add(TextSpan(text: lastListWidget.data!));
                      } else if (lastListWidget.textSpan != null) {
                        spans.addAll(lastListWidget.textSpan!.children!);
                      }
                    } else {
                      spans.add(WidgetSpan(child: lastListWidget));
                    }
                    spans.add(WidgetSpan(child: imagePlaceholder));

                    list[listLength - 1] = SelectableText.rich(
                      TextSpan(children: spans),
                      onTap: () {
                        if (textOnTap != null) {
                          textOnTap();
                        }
                      },
                    );
                  }
                } else {
                  if (StringUtil.isNotBlank(handledStr)) {
                    handledStr = _closeHandledStr(handledStr, inlines);
                  }
                  inlines.add(imagePlaceholder);
                }
              } else {
                // block
                handledStr = _closeHandledStr(handledStr, inlines);
                _closeInlines(inlines, list, textOnTap: textOnTap);
                var imageIndex = imageList.length - 1;
                var imageWidget = ContentImageComponent(
                  imageUrl: subStr,
                  imageList: imageList,
                  imageIndex: imageIndex,
                );
                list.add(imageWidget);
              }
            } else {
              // inline
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentLinkComponent(link: subStr));
            }
          } else if (pathType == "video") {
            if (showVideo && !PlatformUtil.isPC()) {
              // block
              handledStr = _closeHandledStr(handledStr, inlines);
              _closeInlines(inlines, list, textOnTap: textOnTap);
              var w = ContentVideoComponent(url: subStr);
              list.add(w);
            } else {
              // inline
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentLinkComponent(link: subStr));
            }
            // // TODO need to handle, this is temp handle
            // handledStr = _addToHandledStr(handledStr, subStr);
          } else if (pathType == "link") {
            if (!showLinkPreview) {
              // inline
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentLinkComponent(link: subStr));
            } else {
              // block
              handledStr = _closeHandledStr(handledStr, inlines);
              _closeInlines(inlines, list, textOnTap: textOnTap);
              // if (!PlatformUtil.isPC() &&
              //     (subStr.contains("youtube.com") ||
              //         subStr.contains("youtu.be"))) {
              //   var w = ContnetYoutubeComponent(
              //     link: subStr,
              //   );
              //   list.add(w);
              // } else {
              var w = ContentLinkPreComponent(
                link: subStr,
              );
              list.add(w);
              // }
            }
          }
        } else if (subStr.indexOf(NOTE_REFERENCES) == 0 ||
            subStr.indexOf(NOTE_REFERENCES_AT) == 0) {
          var key = subStr.replaceFirst(NOTE_REFERENCES_AT, "");
          key = key.replaceFirst(NOTE_REFERENCES, "");
          if (Nip19.isPubkey(key)) {
            // inline
            // mention user
            key = Nip19.decode(key);
            handledStr = _closeHandledStr(handledStr, inlines);
            inlines.add(ContentMentionUserComponent(pubkey: key));
          } else if (Nip19.isNoteId(key)) {
            // block
            key = Nip19.decode(key);
            handledStr = _closeHandledStr(handledStr, inlines);
            _closeInlines(inlines, list, textOnTap: textOnTap);
            var widget = EventQuoteComponent(
              id: key,
              showVideo: showVideo,
            );
            list.add(widget);
          } else if (NIP19Tlv.isNprofile(key)) {
            var nprofile = NIP19Tlv.decodeNprofile(key);
            if (nprofile != null) {
              // inline
              // mention user
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentMentionUserComponent(pubkey: nprofile.pubkey));
            } else {
              handledStr = _addToHandledStr(handledStr, subStr);
            }
          } else if (NIP19Tlv.isNrelay(key)) {
            var nrelay = NIP19Tlv.decodeNrelay(key);
            if (nrelay != null) {
              // inline
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentRelayComponent(nrelay.addr));
            } else {
              handledStr = _addToHandledStr(handledStr, subStr);
            }
          } else if (NIP19Tlv.isNevent(key)) {
            var nevent = NIP19Tlv.decodeNevent(key);
            if (nevent != null) {
              // block
              handledStr = _closeHandledStr(handledStr, inlines);
              _closeInlines(inlines, list, textOnTap: textOnTap);
              var widget = EventQuoteComponent(
                id: nevent.id,
                showVideo: showVideo,
              );
              list.add(widget);
            } else {
              handledStr = _addToHandledStr(handledStr, subStr);
            }
          } else {
            handledStr = _addToHandledStr(handledStr, subStr);
          }
        } else if (subStr.indexOf(MENTION_USER) == 0) {
          var key = subStr.replaceFirst("@", "");
          // inline
          // mention user
          key = Nip19.decode(key);
          handledStr = _closeHandledStr(handledStr, inlines);
          inlines.add(ContentMentionUserComponent(pubkey: key));
        } else if (subStr.indexOf(MENTION_NOTE) == 0) {
          var key = subStr.replaceFirst("@", "");
          // block
          key = Nip19.decode(key);
          handledStr = _closeHandledStr(handledStr, inlines);
          _closeInlines(inlines, list, textOnTap: textOnTap);
          var widget = EventQuoteComponent(
            id: key,
            showVideo: showVideo,
          );
          list.add(widget);
        } else if (subStr.indexOf(LNBC) == 0) {
          // block
          handledStr = _closeHandledStr(handledStr, inlines);
          _closeInlines(inlines, list, textOnTap: textOnTap);
          var w = ContentLnbcComponent(lnbc: subStr);
          list.add(w);
        } else if (subStr.indexOf(LIGHTNING) == 0) {
          // block
          handledStr = _closeHandledStr(handledStr, inlines);
          _closeInlines(inlines, list, textOnTap: textOnTap);
          var w = ContentLnbcComponent(lnbc: subStr);
          list.add(w);
        } else if (subStr.contains(OTHER_LIGHTNING)) {
          // block
          handledStr = _closeHandledStr(handledStr, inlines);
          _closeInlines(inlines, list, textOnTap: textOnTap);
          var w = ContentLnbcComponent(lnbc: subStr);
          list.add(w);
        } else if (subStr.indexOf("#[") == 0 &&
            subStr.length > 3 &&
            event != null) {
          // mention
          var endIndex = subStr.indexOf("]");
          var indexStr = subStr.substring(2, endIndex);
          var index = int.tryParse(indexStr);
          if (index != null && event.tags.length > index) {
            var tag = event.tags[index];
            if (tag.length > 1) {
              var tagType = tag[0];
              if (tagType == "e") {
                // block
                // mention event
                handledStr = _closeHandledStr(handledStr, inlines);
                _closeInlines(inlines, list, textOnTap: textOnTap);
                var widget = EventQuoteComponent(
                  id: tag[1],
                  showVideo: showVideo,
                );
                list.add(widget);
              } else if (tagType == "p") {
                // inline
                // mention user
                handledStr = _closeHandledStr(handledStr, inlines);
                inlines.add(ContentMentionUserComponent(pubkey: tag[1]));
              } else {
                handledStr = _addToHandledStr(handledStr, subStr);
              }
            }
          }
        } else if (subStr.indexOf("#") == 0 &&
            subStr.indexOf("[") != 1 &&
            subStr.length > 1 &&
            subStr.substring(1) != "#") {
          // inline
          // tag
          handledStr = _closeHandledStr(handledStr, inlines);
          inlines.add(ContentTagComponent(tag: subStr));
        } else {
          var length = subStr.length;
          if (length > 2) {
            if (subStr.substring(0, 1) == ":" &&
                subStr.substring(length - 1) == ":" &&
                tagInfos != null) {
              var imagePath = tagInfos.emojiMap[subStr];
              if (StringUtil.isNotBlank(imagePath)) {
                handledStr = _closeHandledStr(handledStr, inlines);

                inlines.add(CachedNetworkImage(
                  width: 30, // it should according to fontSize
                  imageUrl: imagePath!,
                  // fit: imageBoxFix,
                  placeholder: (context, url) => Container(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  cacheManager: localCacheManager,
                ));
                continue;
              }
            }
          }

          handledStr = _addToHandledStr(handledStr, subStr);
        }
      }

      handledStr = _closeHandledStr(handledStr, inlines);
      _closeInlines(inlines, list, textOnTap: textOnTap);
    }

    if (imageListMode && decodeInfo.imageNum > 1) {
      // showImageList in bottom
      List<Widget> imageWidgetList = [];
      var index = 0;
      for (var image in imageList) {
        imageWidgetList.add(SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.only(right: Base.BASE_PADDING_HALF),
            width: CONTENT_IMAGE_LIST_HEIGHT,
            height: CONTENT_IMAGE_LIST_HEIGHT,
            child: ContentImageComponent(
              imageUrl: image,
              imageList: imageList,
              imageIndex: index,
              height: CONTENT_IMAGE_LIST_HEIGHT,
              width: CONTENT_IMAGE_LIST_HEIGHT,
              // imageBoxFix: BoxFit.fitWidth,
            ),
          ),
        ));
        index++;
      }

      list.add(Container(
        height: CONTENT_IMAGE_LIST_HEIGHT,
        width: double.infinity,
        child: CustomScrollView(
          slivers: imageWidgetList,
          scrollDirection: Axis.horizontal,
        ),
      ));
    }

    return list;
  }

  static const double CONTENT_IMAGE_LIST_HEIGHT = 90;

  static String? getPathType(String path) {
    var strs = path.split("?");
    var index = strs[0].lastIndexOf(".");
    if (index == -1) {
      return null;
    }

    path = strs[0];
    var n = path.substring(index);
    n = n.toLowerCase();

    if (n == ".png" ||
        n == ".jpg" ||
        n == ".jpeg" ||
        n == ".gif" ||
        n == ".webp") {
      return "image";
    } else if (n == ".mp4" || n == ".mov" || n == ".wmv") {
      return "video";
    } else {
      if (path.contains("void.cat/d/")) {
        return "image";
      }
      return "link";
    }
  }
}

class ContentDecoderInfo {
  int imageNum = 0;
  List<List<String>> strs = [];
}
