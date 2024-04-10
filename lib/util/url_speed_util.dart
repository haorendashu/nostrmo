import 'package:nostrmo/util/dio_util.dart';

class UrlSpeedUtil {
  static Future<int> test(String url) async {
    if (url.indexOf("wss") == 0) {
      url = url.replaceFirst("wss", "https");
    } else if (url.indexOf("ws") == 0) {
      url = url.replaceFirst("ws", "http");
    }

    var begin = DateTime.now().millisecondsSinceEpoch;
    try {
      await DioUtil.getDio().head(url);
    } catch (e) {
      print(e);
      return -1;
    }
    return DateTime.now().millisecondsSinceEpoch - begin;
  }
}
