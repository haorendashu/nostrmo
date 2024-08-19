import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/later_function.dart';

class CommunityApprovedProvider extends ChangeNotifier with LaterFunction {
  Map<String, int> _approvedMap = {};

  List<String> eids = [];

  List<Event> penddingEvents = [];

  bool check(String pubkey, String eid, {AId? aId}) {
    if (_approvedMap[eid] != null || aId == null) {
      return true;
    }

    if (contactListProvider.getContact(pubkey) != null ||
        pubkey == nostr!.publicKey) {
      return true;
    }

    // plan to query
    eids.add(eid);
    later(laterFunction);

    return false;
  }

  void laterFunction() {
    if (eids.isNotEmpty) {
      // load
      Map<String, dynamic> filter = {};
      filter["kinds"] = [EventKind.COMMUNITY_APPROVED];
      List<String> ids = [];
      ids.addAll(eids);
      filter["#e"] = ids;
      eids.clear();
      nostr!.query([filter], onEvent);
    }

    if (penddingEvents.isNotEmpty) {
      bool updated = false;

      for (var e in penddingEvents) {
        var eid = getEId(e);
        if (eid != null) {
          // TODO need to check pubkey is Moderated or not.
          if (_approvedMap[eid] == null) {
            updated = true;
          }

          _approvedMap[eid] = 1;
        }
      }

      penddingEvents.clear();
      if (updated) {
        notifyListeners();
      }
    }
  }

  void onEvent(Event e) {
    penddingEvents.add(e);
    later(laterFunction);
  }

  String? getEId(Event e) {
    var tags = e.tags;
    for (var tag in tags) {
      if (tag.length > 1) {
        var key = tag[0];
        var value = tag[1];

        if (key == "e") {
          return value as String;
        }
      }
    }

    return null;
  }
}
