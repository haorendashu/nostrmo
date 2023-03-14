import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/util/lazy_function.dart';

/// a memory event box
/// use to hold event received from relay and offer event List to ui
class EventMemBox with LazyFunction {
  List<Event> _pendingList = [];

  List<Event> _eventList = [];

  Map<String, int> _idMap = {};

  EventMemBox() {
    lazyTimeMS = 800;
  }

  _handlePendingList() {
    print("_handlePendingList");

    _eventList.addAll(_pendingList);
    _pendingList.clear();
    _eventList.sort((event1, event2) {
      return event2.createdAt - event1.createdAt;
    });
  }

  bool add(Event event) {
    if (_idMap[event.id] != null) {
      return false;
    }

    _idMap[event.id] = 1;
    _pendingList.add(event);
    lazy(_handlePendingList, null);
    return true;
  }

  void addBox(EventMemBox b) {
    var all = b.all();
    for (var event in all) {
      if (_idMap[event.id] == null) {
        _idMap[event.id] = 1;
        _pendingList.add(event);
      }
    }
    lazy(_handlePendingList, null);
  }

  int length() {
    return _eventList.length;
  }

  List<Event> all() {
    return _eventList;
  }

  List<Event> suList(int start, int limit) {
    var length = _eventList.length;
    if (start > length) {
      return [];
    }
    if (start + limit > length) {
      return _eventList.sublist(start, length);
    }
    return _eventList.sublist(start, limit);
  }

  Event? get(int index) {
    if (_eventList.length < index) {
      return null;
    }

    return _eventList[index];
  }
}
