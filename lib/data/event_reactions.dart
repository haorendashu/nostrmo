import 'package:nostr_dart/nostr_dart.dart';

import '../../client/event_kind.dart' as kind;
import '../client/zap_num_util.dart';
import '../main.dart';

class EventReactions {
  String id;

  int replyNum = 0;

  List<Event> replies = [];

  int repostNum = 0;

  List<Event> reposts = [];

  int likeNum = 0;

  List<Event> likes = [];

  List<Event>? myLikeEvents;

  int zapNum = 0;

  List<Event> zaps = [];

  Map<String, int> eventIdMap = {};

  EventReactions(this.id);

  DateTime accessTime = DateTime.now();

  DateTime dataTime = DateTime.now();

  EventReactions clone() {
    return EventReactions(id)
      ..replyNum = replyNum
      ..replies = replies
      ..repostNum = repostNum
      ..reposts = reposts
      ..likeNum = likeNum
      ..likes = likes
      ..myLikeEvents = myLikeEvents
      ..zaps = zaps
      ..zapNum = zapNum
      ..eventIdMap = eventIdMap
      ..accessTime = accessTime
      ..dataTime = dataTime;
  }

  void access(DateTime t) {
    accessTime = t;
  }

  bool onEvent(Event event) {
    dataTime = DateTime.now();

    var id = event.id;
    if (eventIdMap[id] == null) {
      eventIdMap[id] = 1;

      if (event.kind == kind.EventKind.TEXT_NOTE) {
        replyNum++;
        replies.add(event);
      } else if (event.kind == kind.EventKind.REPOST) {
        repostNum++;
        reposts.add(event);
      } else if (event.kind == kind.EventKind.REACTION) {
        if (event.content == "-") {
          likeNum--;
        } else {
          likeNum++;
          likes.add(event);
          if (event.pubKey == nostr!.publicKey) {
            myLikeEvents ??= [];
            myLikeEvents!.add(event);
          }
        }
      } else if (event.kind == kind.EventKind.ZAP) {
        zapNum += ZapNumUtil.getNumFromZapEvent(event);
        zaps.add(event);
      }

      return true;
    }

    return false;
  }
}
