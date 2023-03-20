import 'package:nostr_dart/nostr_dart.dart';

class EventRelation {
  List<String> tagPList = [];
  List<String> tagEList = [];

  String? rootId;

  String? replyId;

  EventRelation.fromEvent(Event event) {
    Map<String, int> pMap = {};
    var length = event.tags.length;
    for (var i = 0; i < length; i++) {
      var tag = event.tags[i];

      var mentionStr = "#[" + i.toString() + "]";
      if (event.content.contains(mentionStr)) {
        continue;
      }

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
          }
        }
      }
    }

    if (tagEList.length == 1 && rootId == null) {
      rootId = tagEList[0];
    } else if (tagEList.length > 1) {
      rootId ??= tagEList.first;
      replyId ??= tagEList.last;
    }

    pMap.remove(event.pubKey);
    tagPList.addAll(pMap.keys);
  }
}
