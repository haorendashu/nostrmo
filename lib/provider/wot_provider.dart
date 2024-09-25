import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';

import '../main.dart';

class WotProvider extends ChangeNotifier {
  Map<String, int> _pubkeys = {};

  Map<String, int> _tempPubkeys = {};

  void addTempFromEvents(List<Event> events) {
    for (var e in events) {
      addTempFromEvent(e);
    }
  }

  void addTempFromEvent(Event event) {
    var tags = event.tags;
    for (var tag in tags) {
      if (tag is List && tag.length > 1) {
        if (tag[0] == "p") {
          _tempPubkeys[tag[1]] = 1;
        }
      }
    }
  }

  bool check(String pubkey) {
    if (_pubkeys.isEmpty) {
      return true;
    }

    if (_pubkeys.containsKey(pubkey)) {
      return true;
    }

    return _tempPubkeys.containsKey(pubkey);
  }

  void init(String pubkey) async {
    clear();

    _pubkeys[pubkey] = 1;

    Map<String, int> tempPubkeyMap = {};

    // The pubkeys you had mentioned. (Trust !)
    if (relayLocalDB != null) {
      var eventMapList = await relayLocalDB!.queryEventByPubkey(pubkey);
      if (eventMapList.isNotEmpty) {
        var events = relayLocalDB!.loadEventFromMaps(eventMapList);
        if (events.isNotEmpty) {
          for (var event in events) {
            var tags = event.tags;
            for (var tag in tags) {
              if (tag is List && tag.length > 1) {
                if (tag[0] == "p") {
                  tempPubkeyMap[tag[1]] = 1;
                }
              }
            }
          }
        }
      }
    }

    // The pubkeys you had followed. (Trust !)
    {
      var contactList = contactListProvider.contactList;
      if (contactList != null) {
        var contacts = contactList.list();
        for (var contact in contacts) {
          tempPubkeyMap[contact.publicKey] = 1;
        }
      }
    }

    Map<String, int> notFoundContactListPubkeys = {};
    var pubkeys = tempPubkeyMap.keys;
    for (var pubkey in pubkeys) {
      _pubkeys[pubkey] = 1;

      // The pubkeys your friend had followed. (Trust !)
      var contactList = metadataProvider.getContactList(pubkey);
      if (contactList != null) {
        var contacts = contactList.list();
        for (var contact in contacts) {
          _pubkeys[contact.publicKey] = 1;

          // your friend's friend's contactList. (Half Trust, don't pull if not exist!)
          var ffContactList = metadataProvider.getContactList(pubkey);
          if (ffContactList != null) {
            var ffContacts = ffContactList.list();
            for (var ffcontact in ffContacts) {
              _pubkeys[ffcontact.publicKey] = 1;
            }
          }
        }
      } else {
        notFoundContactListPubkeys[pubkey] = 1;
      }
    }

    Future.delayed(const Duration(minutes: 2), () {
      if (nostr != null) {
        var tempPubkeys = notFoundContactListPubkeys.keys;
        for (var pubkey in tempPubkeys) {
          metadataProvider.update(pubkey);
        }
      }
    });
  }

  void clear() {
    _pubkeys.clear();
  }
}
