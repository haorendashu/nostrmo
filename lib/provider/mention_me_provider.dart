import 'package:flutter/material.dart';

import '../../client/event_kind.dart' as kind;
import '../client/event.dart';
import '../client/filter.dart';
import '../client/nostr.dart';
import '../data/event_mem_box.dart';
import '../main.dart';
import '../util/peddingevents_later_function.dart';
import '../util/string_util.dart';

class MentionMeProvider extends ChangeNotifier
    with PenddingEventsLaterFunction {
  late int _initTime;

  late EventMemBox eventBox;

  MentionMeProvider() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox = EventMemBox();
  }

  void refresh() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox.clear();
    doQuery();

    mentionMeNewProvider.clear();
  }

  void deleteEvent(String id) {
    var result = eventBox.delete(id);
    if (result) {
      notifyListeners();
    }
  }

  int lastTime() {
    return _initTime;
  }

  List<String> _subscribeIds = [];

  List<int> queryEventKinds() {
    return [
      kind.EventKind.TEXT_NOTE,
      kind.EventKind.REPOST,
      kind.EventKind.GENERIC_REPOST,
      kind.EventKind.ZAP,
      kind.EventKind.LONG_FORM,
    ];
  }

  String? subscribeId;

  void doQuery({Nostr? targetNostr, bool initQuery = false, int? until}) {
    targetNostr ??= nostr!;
    var filter = Filter(
      kinds: queryEventKinds(),
      until: until ?? _initTime,
      limit: 50,
      p: [targetNostr.publicKey],
    );

    if (subscribeId != null) {
      try {
        targetNostr.unsubscribe(subscribeId!);
      } catch (e) {}
    }

    subscribeId = _doQueryFunc(targetNostr, filter, initQuery: initQuery);
  }

  String _doQueryFunc(Nostr targetNostr, Filter filter,
      {bool initQuery = false}) {
    var subscribeId = StringUtil.rndNameStr(12);
    if (initQuery) {
      // targetNostr.pool.subscribe([filter.toJson()], onEvent, subscribeId);
      targetNostr.addInitQuery([filter.toJson()], onEvent, id: subscribeId);
    } else {
      if (!eventBox.isEmpty()) {
        var activeRelays = targetNostr.activeRelays();
        var oldestCreatedAts =
            eventBox.oldestCreatedAtByRelay(activeRelays, _initTime);
        Map<String, List<Map<String, dynamic>>> filtersMap = {};
        for (var relay in activeRelays) {
          var oldestCreatedAt = oldestCreatedAts.createdAtMap[relay.url];
          if (oldestCreatedAt != null) {
            filter.until = oldestCreatedAt;
            filtersMap[relay.url] = [filter.toJson()];
          }
        }
        targetNostr.queryByFilters(filtersMap, onEvent, id: subscribeId);
      } else {
        targetNostr.query([filter.toJson()], onEvent, id: subscribeId);
      }
    }
    return subscribeId;
  }

  void onEvent(Event event) {
    later(event, (list) {
      var result = eventBox.addList(list);
      if (result) {
        notifyListeners();
      }
    }, null);
  }

  void clear() {
    eventBox.clear();
    notifyListeners();
  }

  void mergeNewEvent() {
    var allEvents = mentionMeNewProvider.eventMemBox.all();

    eventBox.addList(allEvents);

    // sort
    eventBox.sort();

    mentionMeNewProvider.clear();

    // update ui
    notifyListeners();
  }
}
