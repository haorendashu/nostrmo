import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/zap_num_util.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_util.dart';
import '../../client/event_kind.dart' as kind;
import '../util/spider_util.dart';

class EventReactions {
  String id;

  List<Event> replies = [];

  int repostNum = 0;

  int likeNum = 0;

  List<Event>? myLikeEvents;

  int zapNum = 0;

  Map<String, int> eventIdMap = {};

  EventReactions(this.id);

  DateTime accessTime = DateTime.now();

  DateTime dataTime = DateTime.now();

  EventReactions clone() {
    return EventReactions(id)
      ..replies = replies
      ..repostNum = repostNum
      ..likeNum = likeNum
      ..myLikeEvents = myLikeEvents
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
        replies.add(event);
      } else if (event.kind == kind.EventKind.REPOST) {
        repostNum++;
      } else if (event.kind == kind.EventKind.REACTION) {
        if (event.content == "-") {
          likeNum--;
        } else {
          likeNum++;
          if (event.pubKey == nostr!.publicKey) {
            myLikeEvents ??= [];
            myLikeEvents!.add(event);
          }
        }
      } else if (event.kind == kind.EventKind.ZAP) {
        zapNum += ZapNumUtil.getNumFromZapEvent(event);
      }

      return true;
    }

    return false;
  }
}
