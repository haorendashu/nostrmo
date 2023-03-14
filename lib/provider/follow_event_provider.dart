import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/cust_nostr.dart';
import 'package:nostrmo/data/event_db.dart';

import '../../client/event_kind.dart' as kind;
import '../client/filter.dart';
import '../main.dart';
import '../util/string_util.dart';

class FollowEventProvider extends ChangeNotifier {
  FollowEventProvider();

  List<String> _subscribeIds = [];

  void subscribe({CustNostr? targetNostr}) {
    targetNostr ??= nostr;
    List<String> subscribeIds = [];
    Iterable<Contact> contactList = contactListProvider.list();
    List<String> ids = [];
    for (Contact contact in contactList) {
      ids.add(contact.publicKey);
      if (ids.length > 100) {
        var subscribeId = StringUtil.rndNameStr(16);
        var filter = Filter(kinds: [kind.EventKind.TEXT_NOTE], authors: ids);
        print(filter.toJson());
        targetNostr!.pool.subscribe([filter.toJson()], _onEvent, subscribeId);
        subscribeIds.add(subscribeId);
      }
    }

    for (var subscribeId in _subscribeIds) {
      targetNostr!.pool.unsubscribe(subscribeId);
    }

    _subscribeIds = subscribeIds;
  }

  Future<void> _onEvent(Event event) async {
    print("followEvent onEvent");
    print(event.toJson());
    // var oldEvent = await EventDB.get(event.id);
    // if (oldEvent == null) {
    //   await EventDB.insert(event);
    // }
  }

  void subscribeBefore({CustNostr? targetNostr}) {
    targetNostr ??= nostr;
    Iterable<Contact> contactList = contactListProvider.list();
    print("queryBefore");
    print(contactList);
    List<String> ids = [];
    for (Contact contact in contactList) {
      ids.add(contact.publicKey);
      if (ids.length > 200) {
        var filter = Filter(
          kinds: [kind.EventKind.TEXT_NOTE],
          authors: ids,
          since: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          limit: 1000,
        );
        print(filter.toJson());
        targetNostr!.pool.query([filter.toJson()], _onBeforeEvent);
      }
    }
  }

  Future<void> _onBeforeEvent(Event event) async {
    print("followEvent onBeforeEvent");
    print(event.toJson());
    // var oldEvent = await EventDB.get(event.id);
    // if (oldEvent == null) {
    //   await EventDB.insert(event);
    // }
  }
}
