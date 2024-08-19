import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/utils/find_event_interface.dart';
import 'package:nostrmo/main.dart';

class EventFindUtil {
  static Future<List<Event>> findEvent(String str, {int limit = 5}) async {
    List<FindEventInterface> finders = [followEventProvider];
    finders.addAll(eventReactionsProvider.allReactions());

    var eventBox = EventMemBox(sortAfterAdd: false);
    for (var finder in finders) {
      var list = finder.findEvent(str, limit: limit);
      if (list.isNotEmpty) {
        eventBox.addList(list);

        if (eventBox.length() >= limit) {
          break;
        }
      }
    }

    if (eventBox.length() < limit && relayLocalDB != null) {
      // try to find something from localRelay
      var filter = Filter(kinds: EventKind.SUPPORTED_EVENTS, limit: 5);
      var filterMap = filter.toJson();
      filterMap["search"] = str;

      var eventMaps = await relayLocalDB!.doQueryEvent(filterMap);
      var events = relayLocalDB!.loadEventFromMaps(eventMaps);
      eventBox.addList(events);
    }

    eventBox.sort();
    return eventBox.all();
  }
}
