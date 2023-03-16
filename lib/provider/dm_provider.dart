import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/dm_session.dart';
import 'package:nostrmo/util/string_util.dart';

import '../../client/event_kind.dart' as kind;
import '../client/cust_nostr.dart';
import '../client/filter.dart';
import '../data/event_db.dart';
import '../main.dart';

class DMProvider extends ChangeNotifier {
  static DMProvider? _dmProvider;

  Map<String, DMSession> _sessions = {};

  List<DMSession> list() {
    var sessions = _sessions.values;
    var l = sessions.toList();
    l.sort((session0, session1) {
      return session1.newestEvent!.createdAt - session0.newestEvent!.createdAt;
    });
    return l;
  }

  Future<void> initDMSessions(String localPubkey) async {
    _sessions.clear();
    var list = await EventDB.list(kind.EventKind.DIRECT_MESSAGE, 0, 10000000);

    Map<String, List<Event>> eventListMap = {};
    for (var event in list) {
      var pubkey = _getPubkey(localPubkey, event);
      if (StringUtil.isNotBlank(pubkey)) {
        var list = eventListMap[pubkey!];
        if (list == null) {
          list = [];
          eventListMap[pubkey] = list;
        }
        list.add(event);
      }
    }

    for (var entry in eventListMap.entries) {
      var pubkey = entry.key;
      var list = entry.value;

      var session = DMSession(pubkey: pubkey);
      session.addEvents(list);

      _sessions[pubkey] = session;
    }
  }

  String? _getPubkey(String localPubkey, Event event) {
    if (event.pubKey != localPubkey) {
      return event.pubKey;
    }

    for (var tag in event.tags) {
      if (tag[0] == "p") {
        return tag[1] as String;
      }
    }
  }

  bool _addEvent(Event event) {
    var pubkey = event.pubKey;
    var session = _sessions[pubkey];
    if (session == null) {
      session = DMSession(pubkey: pubkey);
      _sessions[pubkey] = session;
    }
    var addResult = session.addEvent(event);

    notifyListeners();
    return addResult;
  }

  void subscribe({CustNostr? targetNostr}) {
    targetNostr ??= nostr;
    var filter0 = Filter(
      kinds: [kind.EventKind.DIRECT_MESSAGE],
      authors: [targetNostr!.publicKey],
    );
    var filter1 = Filter(
      kinds: [kind.EventKind.DIRECT_MESSAGE],
      p: [targetNostr.publicKey],
    );

    targetNostr.pool.subscribe([filter0.toJson(), filter1.toJson()], (event) {
      print("dmEvent:");
      print(event);
      var addResult = _addEvent(event);
      // save to local
      if (addResult) {
        EventDB.insert(event);
      }
    });
  }
}
