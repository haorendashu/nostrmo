import 'dart:developer';

import 'package:nostrmo/client/event.dart';

class ContentEventTagInfos {
  Map<String, String> emojiMap = {};

  ContentEventTagInfos.fromEvent(Event event) {
    for (var tag in event.tags) {
      if (tag is List<dynamic> && tag.length > 1) {
        var key = tag[0];
        if (key == "emoji" && tag.length > 2) {
          emojiMap[":${tag[1]}:"] = tag[2];
        }
      }
    }
  }
}
