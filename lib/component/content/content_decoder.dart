import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/component/content/content_image_component.dart';
import 'package:nostrmo/component/content/content_link_component.dart';
import 'package:nostrmo/component/content/content_lnbc_component.dart';
import 'package:nostrmo/component/content/content_mention_user_component.dart';
import 'package:nostrmo/component/content/content_tag_component.dart';
import 'package:nostrmo/component/content/content_video_component.dart';
import 'package:nostrmo/component/event/event_quote_component.dart';
import 'package:nostrmo/util/string_util.dart';

import 'content_link_pre_component.dart';
import 'content_str_link_component.dart';

class ContentDecoder {
  static const OTHER_LIGHTNING = "lightning=";

  static const LIGHTNING = "lightning:";

  static const LNBC = "lnbc";

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
          list.add(SelectableText(
            inlines[0],
            onTap: () {
              if (textOnTap != null) {
                textOnTap();
              }
            },
          ));
        } else {
          list.add(inlines[0]);
        }
      } else {
        List<InlineSpan> spans = [];
        for (var inline in inlines) {
          if (inline is String) {
            spans.add(TextSpan(text: inline + " "));
          } else {
            spans.add(WidgetSpan(child: inline));
          }
        }
        list.add(SelectableText.rich(
          TextSpan(children: spans),
          onTap: () {
            if (textOnTap != null) {
              textOnTap();
            }
          },
        ));
      }
      inlines.clear();
    }
  }

  static List<Widget> decode(
    BuildContext context,
    String? content,
    Event? event, {
    Function? textOnTap,
    bool showVideo = false,
    bool showLinkPreview = true,
  }) {
    if (StringUtil.isBlank(content) && event != null) {
      content = event.content;
    }
    content = content!.trim();
    List<Widget> list = [];
    content = content.replaceAll("\r\n", "\n");
    content = content.replaceAll("\n\n", "\n");
    var strs = content.split("\n");

    List<String> imageList = [];

    for (var str in strs) {
      List<dynamic> inlines = [];
      String handledStr = "";

      ///
      /// 1、str: add to handledStr
      /// 2、inline: put handledStr to inlines, put currentInline to inlines, new a new handledStr
      /// 3、block: put handledStr to inlines, put inlines to list as a line, put block to list as a line, new a new handledStr
      /// 4、if handledStr not empty, put to inlines, put inlines to list as a line
      ///
      var subStrs = str.split(" ");
      for (var subStr in subStrs) {
        if (subStr.indexOf("http") == 0) {
          // link, image, video etc
          var pathType = getPathType(subStr);
          if (pathType == "image") {
            imageList.add(subStr);

            // block
            handledStr = _closeHandledStr(handledStr, inlines);
            _closeInlines(inlines, list, textOnTap: textOnTap);
            var imageWidget = ContentImageComponent(
              imageUrl: subStr,
              imageList: imageList,
            );
            list.add(imageWidget);
          } else if (pathType == "video") {
            if (showVideo) {
              // block
              handledStr = _closeHandledStr(handledStr, inlines);
              _closeInlines(inlines, list);
              var w = ContentVideoComponent(url: subStr);
              list.add(w);
            } else {
              // inline
              handledStr = _closeHandledStr(handledStr, inlines);
              inlines.add(ContentStrLinkComponent(
                str: subStr,
                onTap: () {
                  if (textOnTap != null) {
                    textOnTap();
                  }
                },
              ));
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
              var w = ContentLinkPreComponent(
                link: subStr,
              );
              list.add(w);
            }
          }
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
                var widget = EventQuoteComponent(id: tag[1]);
                list.add(widget);
              } else if (tagType == "p") {
                // inline
                // mention user
                handledStr = _closeHandledStr(handledStr, inlines);
                inlines.add(ContentMentionUserComponent(pubkey: tag[1]));
              } else {
                // TODO need to handle, this is temp handle
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
          handledStr = _addToHandledStr(handledStr, subStr);
        }
      }

      handledStr = _closeHandledStr(handledStr, inlines);
      _closeInlines(inlines, list, textOnTap: textOnTap);
    }
    return list;
  }

  static String? getPathType(String path) {
    var index = path.lastIndexOf(".");
    if (index == -1) {
      return null;
    }

    var n = path.substring(index);
    n = n.toLowerCase();

    var strs = n.split("?");
    var s = strs[0];

    if (s == ".png" ||
        s == ".jpg" ||
        s == ".jpeg" ||
        s == ".gif" ||
        s == ".webp") {
      return "image";
    } else if (s == ".mp4" || s == ".mov" || s == ".wmv") {
      return "video";
    } else {
      return "link";
    }
  }
}
