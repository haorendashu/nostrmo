import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/data/event_mem_box.dart';

class DMSession {
  final String pubkey;

  EventMemBox _box = EventMemBox();

  DMSession({required this.pubkey});

  bool addEvent(Event event) {
    return _box.add(event);
  }

  void addEvents(List<Event> events) {
    _box.addList(events);
  }

  Event? get newestEvent {
    return _box.newestEvent;
  }
}
