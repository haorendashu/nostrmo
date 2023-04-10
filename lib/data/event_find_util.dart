import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/data/event_mem_box.dart';
import 'package:nostrmo/main.dart';

import '../util/find_event_interface.dart';

class EventFindUtil {
  static List<Event> findEvent(String str, {int? limit = 5}) {
    List<FindEventInterface> finders = [followEventProvider];
    finders.addAll(eventReactionsProvider.allReactions());

    var eventBox = EventMemBox(sortAfterAdd: false);
    for (var finder in finders) {
      var list = finder.findEvent(str, limit: limit);
      if (list.isNotEmpty) {
        eventBox.addList(list);

        if (limit != null && eventBox.length() >= limit) {
          break;
        }
      }
    }

    return eventBox.all();
  }
}
