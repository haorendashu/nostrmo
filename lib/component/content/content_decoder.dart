import 'package:flutter/material.dart';
import 'package:nostrmo/component/content/content_image_component.dart';
import 'package:nostrmo/component/content/content_link_component.dart';
import 'package:nostrmo/component/content/content_tag_component.dart';
import 'package:nostrmo/util/string_util.dart';

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

  static String _closeHandledStr(String handledStr, List<Widget> inlines) {
    if (StringUtil.isNotBlank(handledStr)) {
      inlines.add(Text(handledStr));
    }
    return "";
  }

  static void _closeInlines(List<Widget> inlines, List<Widget> list) {
    if (inlines.isNotEmpty) {
      if (inlines.length == 1) {
        list.add(inlines[0]);
      } else {
        // list.add(Wrap(
        //   children: inlines,
        // ));
        List<InlineSpan> spans = [];
        for (var inline in inlines) {
          if (inline is Text) {
            spans.add(TextSpan(text: inline.data! + " "));
          } else {
            spans.add(WidgetSpan(child: inline));
          }
        }
        list.add(Text.rich(TextSpan(children: spans)));
      }
      inlines.clear();
    }
  }

  static List<Widget> decode(String content) {
    content = content.trim();
    List<Widget> list = [];
    content = content.replaceAll("\r\n", "\n");
    content = content.replaceAll("\n\n", "\n");
    var strs = content.split("\n");

    for (var str in strs) {
      List<Widget> inlines = [];
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
            // block
            handledStr = _closeHandledStr(handledStr, inlines);
            _closeInlines(inlines, list);
            var imageWidget = ContentImageComponent(imageUrl: subStr);
            list.add(imageWidget);
          } else if (pathType == "video") {
            // block
            // TODO need to handle, this is temp handle
            handledStr = _addToHandledStr(handledStr, subStr);
          } else if (pathType == "link") {
            // inline
            handledStr = _closeHandledStr(handledStr, inlines);
            inlines.add(ContentLinkComponent(link: subStr));
          }
        } else if (subStr.indexOf(LNBC) == 0) {
          // block
          // TODO need to handle, this is temp handle
          handledStr = _addToHandledStr(handledStr, subStr);
        } else if (subStr.indexOf(LIGHTNING) == 0) {
          // block
          // TODO need to handle, this is temp handle
          handledStr = _addToHandledStr(handledStr, subStr);
        } else if (subStr.contains(OTHER_LIGHTNING)) {
          // block
          // TODO need to handle, this is temp handle
          handledStr = _addToHandledStr(handledStr, subStr);
        } else if (subStr.indexOf("#") == 0 && subStr.indexOf("[") == 1) {
          // inline
          // mention
          // TODO need to handle, this is temp handle
          handledStr = _addToHandledStr(handledStr, subStr);
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
      _closeInlines(inlines, list);
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
