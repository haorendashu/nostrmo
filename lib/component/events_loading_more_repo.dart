import 'package:loading_more_list/loading_more_list.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_mem_box.dart';

typedef EventMemBox GetEventBoxFunc();

class EventsLoadingMoreRepo extends LoadingMoreBase<Event> {
  int queryInterval = 1000 * 3;

  int? until;

  int queryLimit = 50;

  DateTime? queryTime;

  int beginQueryNum = 0;

  bool forceUserLimit = false;

  GetEventBoxFunc? getEventBox;

  @override
  Future<bool> loadData([bool isLoadMoreAction = false]) async {
    assert(getEventBox != null, "getEventBox can't be null");

    var eventMemBox = getEventBox!();
    var now = DateTime.now();
    // check if query just now
    if (queryTime != null &&
        now.millisecondsSinceEpoch - queryTime!.millisecondsSinceEpoch <
            queryInterval) {
      return false;
    }

    beginQueryNum = eventMemBox.length();
    queryTime = DateTime.now();

    var currentLength = eventMemBox.length();
    if (currentLength - beginQueryNum == 0) {
      forceUserLimit = true;
    } else {
      forceUserLimit = false;
    }

    // query from the oldest event createdAt
    var oldestEvent = eventMemBox.oldestEvent;
    if (oldestEvent != null) {
      until = oldestEvent.createdAt;
    }

    if (doQuery != null) {
      await doQuery!();
    }

    return true;
  }

  Function? doQuery;

  @override
  Event operator [](int index) {
    assert(getEventBox != null, "getEventBox can't be null");
    var eventBox = getEventBox!();
    assert(index < eventBox.length(), "index overflow");
    var event = eventBox.get(index);
    assert(event != null, "event not found");
    return event!;
  }

  @override
  void operator []=(int index, Event value) {
    assert(getEventBox != null, "getEventBox can't be null");
    var eventBox = getEventBox!();
    var list = eventBox.all();
    list[index] = value;
  }

  @override
  void add(Event element) {
    assert(getEventBox != null, "getEventBox can't be null");
    getEventBox!().add(element);
  }

  @override
  int get length {
    assert(getEventBox != null, "getEventBox can't be null");
    return getEventBox!().length();
  }

  // don't knwo how to adapt for this implement
  // @override
  // set length(int newLength) => _array.length = newLength;
}
