import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/util/peddingevents_lazy_function.dart';

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
    penddingEvents.add(event);
    await _onEventFunc();
  }

  void subscribeBefore({CustNostr? targetNostr}) {
    var filter = Filter(
      kinds: [kind.EventKind.TEXT_NOTE],
      until: _initTime,
      limit: 100,
    );
    _subscribeBeforeIds = _subscribeFunc(
        targetNostr, _subscribeBeforeIds, filter, _onBeforeEvent);
  }

  Future<void> _onBeforeEvent(Event event) async {
    _eventExist = true;
    penddingBeforeEvents.add(event);
    await _onEventFunc();
  }

  List<Event> penddingEvents = [];
  List<Event> penddingBeforeEvents = [];

  Future<void> _onEventFunc() async {
    if (beforeBox.isEmpty()) {
      lazyTimeMS = 200;
    } else {
      lazyTimeMS = 2000;
    }

    lazy(() {
      bool addResult = false;
      bool beforeAddResult = false;
      if (penddingEvents.isNotEmpty) {
        addResult = newBox.addList(penddingEvents);
        penddingEvents.clear();
      }
      if (penddingBeforeEvents.isNotEmpty) {
        beforeAddResult = beforeBox.addList(penddingBeforeEvents);
        penddingBeforeEvents.clear();
      }

      if (addResult || beforeAddResult) {
        notifyListeners();
      }
    }, null);
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
