import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/util/peddingevents_later_function.dart';

import '../../client/event_kind.dart' as kind;
import '../client/cust_contact_list.dart';
import '../client/cust_nostr.dart';
import '../client/filter.dart';
import '../data/event_mem_box.dart';
import '../main.dart';
import '../util/string_util.dart';

class FollowEventProvider extends ChangeNotifier
    with PenddingEventsLaterFunction {
  late int _initTime;

  late EventMemBox eventBox;

  late EventMemBox postsBox;

  FollowEventProvider() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox = EventMemBox(sortAfterAdd: false); // sortAfterAdd by call
    postsBox = EventMemBox(sortAfterAdd: false);
  }

  List<Event> eventsByPubkey(String pubkey) {
    return eventBox.listByPubkey(pubkey);
  }

  void refresh() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox.clear();
    postsBox.clear();
    doQuery();
  }

  List<String> _subscribeIds = [];

  void deleteEvent(String id) {
    postsBox.delete(id);
    var result = eventBox.delete(id);
    if (result) {
      notifyListeners();
    }
  }

  void doQuery({CustNostr? targetNostr, bool initQuery = false, int? until}) {
    var filter = Filter(
      kinds: [kind.EventKind.TEXT_NOTE, kind.EventKind.REPOST],
      until: until ?? _initTime,
      limit: 100,
    );
    targetNostr ??= nostr!;

    doUnscribe(targetNostr);

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

  void doUnscribe(CustNostr targetNostr) {
    if (_subscribeIds.isNotEmpty) {
      for (var subscribeId in _subscribeIds) {
        try {
          targetNostr.pool.unsubscribe(subscribeId);
        } catch (e) {}
      }
      _subscribeIds.clear();
    }
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
    if (eventBox.isEmpty()) {
      laterTimeMS = 200;
    } else {
      laterTimeMS = 500;
    }
    later(event, (list) {
      bool added = false;
      for (var e in list) {
        var result = eventBox.add(e);
        if (result) {
          // add success
          added = true;

          // check if is posts (no tag e)
          bool isPosts = true;
          for (var tag in e.tags) {
            if (tag.length > 0 && tag[0] == "e") {
              isPosts = false;
              break;
            }
          }
          if (isPosts) {
            postsBox.add(e);
          }
        }
      }

      if (added) {
        // sort
        eventBox.sort();
        postsBox.sort();

        // update ui
        notifyListeners();
      }
    }, null);
  }

  void clear() {
    eventBox.clear();
    postsBox.clear();

    doUnscribe(nostr!);

    notifyListeners();
  }

  void metadataUpdatedCallback(CustContactList? _contactList) {
    if (eventBox.isEmpty() && _contactList != null && !_contactList.isEmpty()) {
      doQuery();
    }
  }
}
