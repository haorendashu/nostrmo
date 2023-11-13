import 'dart:developer';

import 'package:nostrmo/client/event.dart';

class ContentEventTagInfos {
  Map<String, String> emojiMap = {};
  Map<String, int> tagMap = {};
  List<MapEntry<String, int>> tagEntryInfos = [];

  ContentEventTagInfos.fromEvent(Event event) {
    for (var tag in event.tags) {
      if (tag is List<dynamic> && tag.length > 1) {
        var key = tag[0];
        var value = tag[1];
        if (key == "emoji" && tag.length > 2) {
          emojiMap[":${tag[1]}:"] = tag[2];
        } else if (key == "t") {
          tagMap[value] = value.length;
        }
      }
    }

    if (tagMap.isNotEmpty) {
      tagEntryInfos = tagMap.entries.toList();
      tagEntryInfos.sort((entry0, entry1) {
        return entry1.value - entry0.value;
      });
    }
  }
}
