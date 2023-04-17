import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';

import '../client/filter.dart';
import '../data/event_mem_box.dart';
import '../main.dart';
import '../util/peddingevents_later_function.dart';
import '../util/string_util.dart';

class MentionMeNewProvider extends ChangeNotifier
    with PenddingEventsLaterFunction {
  EventMemBox eventMemBox = EventMemBox();

  int? _localSince;

  String? subscribeId;

  void queryNew() {
    if (subscribeId != null) {
      try {
        nostr!.pool.unsubscribe(subscribeId!);
      } catch (e) {}
    }

    _localSince =
        _localSince == null || mentionMeProvider.lastTime() > _localSince!
            ? mentionMeProvider.lastTime()
            : _localSince;

    subscribeId = StringUtil.rndNameStr(12);
    var filter = Filter(
      since: _localSince! + 1,
      kinds: mentionMeProvider.queryEventKinds(),
      p: [nostr!.publicKey],
    );
    nostr!.pool.query([filter.toJson()], (event) {
      later(event, handleEvents, null);
    }, subscribeId);
  }

  handleEvents(List<Event> events) {
    eventMemBox.addList(events);
    _localSince = eventMemBox.newestEvent!.createdAt;
    notifyListeners();
  }

  void clear() {
    eventMemBox.clear();

    notifyListeners();
  }
}
