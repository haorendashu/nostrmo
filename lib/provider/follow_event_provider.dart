import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/util/peddingevents_later_function.dart';

import '../../client/event_kind.dart' as kind;
import '../client/cust_nostr.dart';
import '../client/filter.dart';
import '../data/event_mem_box.dart';
import '../main.dart';
import '../util/string_util.dart';

class FollowEventProvider extends ChangeNotifier
    with PenddingEventsLaterFunction {
  late int _initTime;

  late EventMemBox eventBox;

  FollowEventProvider() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox = EventMemBox();
  }

  List<Event> eventsByPubkey(String pubkey) {
    return eventBox.listByPubkey(pubkey);
  }

  void refresh() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox.clear();
    doQuery();
  }

  List<String> _subscribeIds = [];

  void doQuery({CustNostr? targetNostr, bool initQuery = false, int? until}) {
    var filter = Filter(
      kinds: [kind.EventKind.TEXT_NOTE, kind.EventKind.REPOST],
      until: until ?? _initTime,
      limit: 50,
    );
    targetNostr ??= nostr!;

    if (_subscribeIds.isNotEmpty) {
      for (var subscribeId in _subscribeIds) {
        try {
          targetNostr.pool.unsubscribe(subscribeId);
        } catch (e) {}
      }
      _subscribeIds.clear();
    }

    List<String> subscribeIds = [];
    Iterable<Contact> contactList = contactListProvider.list();
    List<String> ids = [];
    for (Contact contact in contactList) {
      ids.add(contact.publicKey);
      if (ids.length > 100) {
        filter.authors = ids;
        var subscribeId =
            _doQueryFunc(targetNostr, filter, initQuery: initQuery);
        subscribeIds.add(subscribeId);
        ids.clear();
      }
    }
    if (ids.isNotEmpty) {
      filter.authors = ids;
      var subscribeId = _doQueryFunc(targetNostr, filter, initQuery: initQuery);
      subscribeIds.add(subscribeId);
    }

    if (!initQuery) {
      _subscribeIds = subscribeIds;
    }
  }

  String _doQueryFunc(CustNostr targetNostr, Filter filter,
      {bool initQuery = false}) {
    var subscribeId = StringUtil.rndNameStr(12);
    if (initQuery) {
      targetNostr.pool.subscribe([filter.toJson()], onEvent, subscribeId);
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
}
