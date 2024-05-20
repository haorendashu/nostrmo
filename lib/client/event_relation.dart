import 'package:nostrmo/client/aid.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/client/nip19/nip19_tlv.dart';
import 'package:nostrmo/client/event_kind.dart' as kind;

import '../util/spider_util.dart';
import 'event.dart';

/// This class is designed for get the relation from event, but it seam to used for get tagInfo from event before event_main display.
class EventRelation {
  late String id;

  late String pubkey;

  List<String> tagPList = [];

  List<String> tagEList = [];

  String? rootId;

  String? rootRelayAddr;

  String? replyId;

  String? replyRelayAddr;

  String? subject;

  bool warning = false;

  AId? aId;

  String? zapraiser;

  String? dTag;

  String? type;

  List<EventZapInfo> zapInfos = [];

  String? innerZapContent;

  String? get replyOrRootId {
    return replyId != null ? replyId : rootId;
  }

  String? get replyOrRootRelayAddr {
    return replyId != null ? replyRelayAddr : rootRelayAddr;
  }

  EventRelation.fromEvent(Event event) {
    id = event.id;
    pubkey = event.pubkey;

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
        var tagKey = tag[0];
        var value = tag[1] as String;
        if (tagKey == "p") {
          // check if is Text Note References
          var nip19Str = "nostr:${Nip19.encodePubKey(value)}";
          if (event.content.contains(nip19Str)) {
            continue;
          }
          nip19Str = NIP19Tlv.encodeNprofile(Nprofile(pubkey: value));
          if (event.content.contains(nip19Str)) {
            continue;
          }

          pMap[value] = 1;
        } else if (tagKey == "e") {
          if (tagLength > 3) {
            var marker = tag[3];
            if (marker == "root") {
              rootId = value;
              rootRelayAddr = tag[2];
            } else if (marker == "reply") {
              replyId = value;
              replyRelayAddr = tag[2];
            } else if (marker == "mention") {
              continue;
            }
          }
          tagEList.add(value);
        } else if (tagKey == "subject") {
          subject = value;
        } else if (tagKey == "content-warning") {
          warning = true;
        } else if (tagKey == "a") {
          aId = AId.fromString(value);
        } else if (tagKey == "zapraiser") {
          zapraiser = value;
        } else if (tagKey == "d") {
          dTag = value;
        } else if (tagKey == "type") {
          type = value;
        } else if (tagKey == "zap" && tagLength > 3) {
          var zapInfo = EventZapInfo.fromTags(tag);
          zapInfos.add(zapInfo);
        } else if (tagKey == "description" &&
            event.kind == kind.EventKind.ZAP) {
          innerZapContent = SpiderUtil.subUntil(value, '\"content\":\"', '\",');
        }
      }
    }

    var tagELength = tagEList.length;
    if (tagELength == 1 && rootId == null && replyId == null) {
      rootId = tagEList[0];
    } else if (tagELength > 1) {
      if (rootId == null && replyId == null) {
        rootId = tagEList.first;
        replyId = tagEList.last;
      } else if (rootId != null && replyId == null) {
        for (var i = tagELength - 1; i > -1; i--) {
          var id = tagEList[i];
          if (id != rootId) {
            replyId = id;
          }
        }
      } else if (rootId == null && replyId != null) {
        for (var i = 0; i < tagELength; i++) {
          var id = tagEList[i];
          if (id != replyId) {
            rootId = id;
          }
        }
      } else {
        rootId ??= tagEList.first;
        replyId ??= tagEList.last;
      }
    }

    if (rootId != null && replyId == rootId && rootRelayAddr == null) {
      rootRelayAddr = replyRelayAddr;
    }

    pMap.remove(event.pubkey);
    tagPList.addAll(pMap.keys);
  }
}

class EventZapInfo {
  late String pubkey;

  late String relayAddr;

  late double weight;

  EventZapInfo(this.pubkey, this.relayAddr, this.weight);

  factory EventZapInfo.fromTags(List tag) {
    var pubkey = tag[1] as String;
    var relayAddr = tag[2] as String;
    var sourceWeidght = tag[3];
    double weight = 1;
    if (sourceWeidght is String) {
      weight = double.parse(sourceWeidght);
    } else if (sourceWeidght is double) {
      weight = sourceWeidght;
    } else if (sourceWeidght is int) {
      weight = sourceWeidght.toDouble();
    }

    return EventZapInfo(pubkey, relayAddr, weight!);
  }
}
