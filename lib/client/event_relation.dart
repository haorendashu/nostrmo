import 'package:nostr_dart/nostr_dart.dart';

class EventRelation {
  List<String> tagPList = [];
  List<String> tagEList = [];

  String? rootId;

  String? replyId;

  EventRelation.fromEvent(Event event) {
    Map<String, int> pMap = {};
    for (var tag in event.tags) {
      var tagLength = tag.length;
      if (tagLength > 1 && tag[1] is String) {
        var value = tag[1] as String;
        if (tag[0] == "p") {
          pMap[value] = 1;
        } else if (tag[0] == "e") {
          tagEList.add(value);
          if (tagLength > 3) {
            var marker = tag[3];
            if (marker == "root") {
              rootId = value;
            } else if (marker == "reply") {
              replyId = value;
            }

            if (rootId == null) {
              rootId = value;
            } else if (replyId == null) {
              replyId = value;
            }
          }
        }
      }
    }
    tagPList.addAll(pMap.keys);
  }
}
