import 'package:nostr_dart/nostr_dart.dart';

import '../../client/event_kind.dart' as kind;
import '../util/spider_util.dart';
import '../util/string_util.dart';

class ZapNumUtil {
  static int getNumFromZapEvent(Event event) {
    if (event.kind == kind.EventKind.ZAP) {
      for (var tag in event.tags) {
        if (tag.length > 1) {
          var tagType = tag[0] as String;
          if (tagType == "bolt11") {
            var zapStr = tag[1] as String;
            return getNumFromStr(zapStr);
          }
        }
      }
    }

    return 0;
  }

  static int getNumFromStr(String zapStr) {
    var numStr = SpiderUtil.subUntil(zapStr, "lnbc", "1p");
    if (StringUtil.isNotBlank(numStr)) {
      var lastStr = numStr.substring(numStr.length - 1);
      if (lastStr == "n") {
        var formatNumStr = numStr.replaceAll("0n", "");
        var num = int.tryParse(formatNumStr);
        if (num != null) {
          return num;
        }
      } else if (lastStr == "u") {
        var formatNumStr = numStr.replaceAll("u", "");
        var num = int.tryParse(formatNumStr);
        if (num != null) {
          return (num * 100);
        }
      }
    }

    return 0;
  }
}
