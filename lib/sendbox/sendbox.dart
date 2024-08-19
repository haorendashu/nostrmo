import 'package:nostr_sdk/event.dart';
import 'package:nostrmo/util/dio_util.dart';

class SendBox {
  static Future<void> submit(Event event, List<String> relays) async {
    var link = "https://sendbox_api.nostrmo.com/api/msg/submit?";
    for (var i = 0; i < relays.length && i < 6; i++) {
      var relayAddr = relays[i];
      link += "&r=" + relayAddr;
    }

    await DioUtil.post(link, event.toJson());
  }
}
