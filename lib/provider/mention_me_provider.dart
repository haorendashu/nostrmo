import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/util/peddingevents_later_function.dart';

import '../../client/event_kind.dart' as kind;
import '../client/cust_nostr.dart';
import '../client/filter.dart';
import '../data/event_mem_box.dart';
import '../main.dart';
import '../util/string_util.dart';

class MentionMeProvider extends ChangeNotifier
    with PenddingEventsLaterFunction {
  late int _initTime;

  late EventMemBox eventBox;

  MentionMeProvider() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox = EventMemBox();
  }

  String? subscribeId;

  void doQuery({CustNostr? targetNostr, bool initQuery = false, int? until}) {
    targetNostr ??= nostr!;
    var filter = Filter(
      kinds: [kind.EventKind.TEXT_NOTE, kind.EventKind.REPOST],
      until: until ?? _initTime,
      limit: 50,
      p: [targetNostr.publicKey],
    );

    if (subscribeId != null) {
      try {
        targetNostr.pool.unsubscribe(subscribeId!);
      } catch (e) {}
    }

    subscribeId = _doQueryFunc(targetNostr, filter, initQuery: initQuery);
  }

  String _doQueryFunc(CustNostr targetNostr, Filter filter,
      {bool initQuery = false}) {
    var subscribeId = StringUtil.rndNameStr(12);
    if (initQuery) {
      // targetNostr.pool.subscribe([filter.toJson()], onEvent, subscribeId);
      targetNostr.pool.addInitQuery([filter.toJson()], onEvent, subscribeId);
    } else {
      targetNostr.pool.query([filter.toJson()], onEvent, subscribeId);
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
}
