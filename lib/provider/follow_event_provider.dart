import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';

import '../../client/event_kind.dart' as kind;
import '../client/cust_nostr.dart';
import '../client/filter.dart';
import '../data/event_mem_box.dart';
import '../main.dart';
import '../util/lazy_function.dart';
import '../util/string_util.dart';

class FollowEventProvider extends ChangeNotifier with LazyFunction {
  bool _eventExist = false;

  late int _initTime;

  FollowEventProvider() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    beforeBox = EventMemBox();
    newBox = EventMemBox();
    lazyTimeMS = 1000;
  }

  bool get eventExist => _eventExist;

  late EventMemBox beforeBox;

  late EventMemBox newBox;

  List<String> _subscribeIds = [];

  List<String> _subscribeBeforeIds = [];

  int get newListNum => newBox.length();

  List<Event> get currentEvents => beforeBox.all();

  List<Event> eventsByPubkey(String pubkey) {
    return beforeBox.listByPubkey(pubkey);
  }

  Event? getBeforeEvent(int index) {
    return beforeBox.get(index);
  }

  void subscribe({CustNostr? targetNostr}) {
    var filter = Filter(
      kinds: [kind.EventKind.TEXT_NOTE],
      since: _initTime,
    );
    _subscribeIds =
        _subscribeFunc(targetNostr, _subscribeIds, filter, _onEvent);
  }

  Future<void> _onEvent(Event event) async {
    print("newBox receive");
    await _onEventFunc(event, newBox);
  }

  void subscribeBefore({CustNostr? targetNostr}) {
    var filter = Filter(
      kinds: [kind.EventKind.TEXT_NOTE],
      until: _initTime,
      limit: 1000,
    );
    _subscribeBeforeIds = _subscribeFunc(
        targetNostr, _subscribeBeforeIds, filter, _onBeforeEvent);
  }

  Future<void> _onBeforeEvent(Event event) async {
    print("beforeBox receive");
    _eventExist = true;
    await _onEventFunc(event, beforeBox);
  }

  Future<void> _onEventFunc(Event event, EventMemBox box) async {
    var addResult = box.add(event);
    if (addResult) {
      // add success
      lazy(() {
        print("followEvent notifyListeners");
        notifyListeners();
      }, null);
    }
  }

  List<String> _subscribeFunc(
      CustNostr? targetNostr,
      List<String> currentSubscribeIds,
      Filter filter,
      Function(Event) onEventFunc) {
    targetNostr ??= nostr;
    List<String> subscribeIds = [];
    Iterable<Contact> contactList = contactListProvider.list();
    List<String> ids = [];
    for (Contact contact in contactList) {
      ids.add(contact.publicKey);
      if (ids.length > 100) {
        filter.authors = ids;
        var subscribeId = _doSubscribe(targetNostr!, filter, onEventFunc);
        subscribeIds.add(subscribeId);
        ids.clear();
      }
    }
    if (ids.isNotEmpty) {
      filter.authors = ids;
      var subscribeId = _doSubscribe(targetNostr!, filter, onEventFunc);
      subscribeIds.add(subscribeId);
    }

    for (var subscribeId in currentSubscribeIds) {
      targetNostr!.pool.unsubscribe(subscribeId);
    }

    return subscribeIds;
  }

  String _doSubscribe(
      CustNostr targetNostr, Filter filter, Function(Event) onEventFunc) {
    var subscribeId = StringUtil.rndNameStr(16);
    targetNostr.pool.subscribe([filter.toJson()], onEventFunc, subscribeId);
    return subscribeId;
  }
}
