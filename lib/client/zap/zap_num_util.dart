import '../../../client/event_kind.dart' as kind;
import '../../util/spider_util.dart';
import '../../util/string_util.dart';
import '../event.dart';

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
      var numStrLength = numStr.length;
      if (numStrLength > 1) {
        var lastStr = numStr.substring(numStr.length - 1);
        var pureNumStr = numStr.substring(0, numStr.length - 1);
        var pureNum = int.tryParse(pureNumStr);
        if (pureNum != null) {
          if (lastStr == "p") {
            return (pureNum * 0.0001).round();
          } else if (lastStr == "n") {
            return (pureNum * 0.1).round();
          } else if (lastStr == "u") {
            return (pureNum * 100).round();
          } else if (lastStr == "m") {
            return (pureNum * 100000).round();
          }
        }
      }
    }

    return 0;
  }
}
