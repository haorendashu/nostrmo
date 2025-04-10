import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/provider/data_util.dart';

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

  String genKey(String pubkey) {
    return "${DataKey.WOT_PRE}$pubkey";
  }

  void init(String pubkey) async {
    var wotText = sharedPreferences.getString(genKey(pubkey));
    if (StringUtil.isNotBlank(wotText)) {
      var pubkeys = wotText!.split(",");
      clear();
      for (var pubkey in pubkeys) {
        _pubkeys[pubkey] = 1;
      }

      Future.delayed(const Duration(minutes: 2), () {
        reload(pubkey, pullNow: true);
      });
    } else {
      reload(pubkey);
    }
  }

  void reload(String pubkey, {bool pullNow = false}) async {
    print("begin to reload wot infos");
    _pubkeys[pubkey] = 1;

    // The pubkeys you had mentioned. (Trust !)
    {
      var filter = Filter(authors: [
        pubkey
      ], kinds: [
        EventKind.TEXT_NOTE,
        EventKind.DIRECT_MESSAGE,
        EventKind.REPOST,
        EventKind.REACTION,
        EventKind.GENERIC_REPOST,
        EventKind.FOLLOW_SETS,
      ]);
      var events = await nostr!.queryEvents([filter.toJson()],
          relayTypes: RelayType.CACHE_AND_LOCAL);

      if (events.isNotEmpty) {
        for (var event in events) {
          var tags = event.tags;
          for (var tag in tags) {
            if (tag is List && tag.length > 1) {
              if (tag[0] == "p") {
                _pubkeys[tag[1]] = 1;
              }
            }
          }
        }
      }
    }

    List<String> followedPubkeys = [];
    // The pubkeys you had followed. (Trust !)
    {
      var contactList = contactListProvider.contactList;
      if (contactList != null) {
        var contacts = contactList.list();
        for (var contact in contacts) {
          var pubkey = contact.publicKey;
          followedPubkeys.add(pubkey);
          _pubkeys[pubkey] = 1;
        }
      }
    }

    // try to load contract from your local
    var length = followedPubkeys.length;
    var times = length ~/ 100;
    for (var i = 0; i < times; i++) {
      var subFollowedPubkeys = followedPubkeys.sublist(i * 100, (i + 1) * 100);
      var ms = DateTime.now().millisecondsSinceEpoch;
      print("begin load");
      await metadataProvider.load(subFollowedPubkeys);
      print("load end ${DateTime.now().millisecondsSinceEpoch - ms}");
      await Future.delayed(const Duration(seconds: 5));
    }
    if (times * 100 < length) {
      var subFollowedPubkeys = followedPubkeys.sublist(times * 100, length);
      await metadataProvider.load(subFollowedPubkeys);
    }

    Map<String, int> notFoundContactListPubkeys = {};
    for (var pubkey in followedPubkeys) {
      // The pubkeys your friend had followed. (Trust !)
      var contactList =
          metadataProvider.getContactList(pubkey, loadData: false);
      if (contactList != null) {
        var contacts = contactList.list();
        for (var contact in contacts) {
          _pubkeys[contact.publicKey] = 1;

          // your friend's friend's contactList. (Half Trust, don't pull if not exist!)
          var ffContactList = metadataProvider.getContactList(contact.publicKey,
              loadData: false);
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

    doPullNotFound() {
      if (nostr != null) {
        var tempPubkeys = notFoundContactListPubkeys.keys;
        for (var pubkey in tempPubkeys) {
          metadataProvider.update(pubkey);
        }
      }
    }

    if (pullNow) {
      doPullNotFound();
    } else {
      Future.delayed(const Duration(minutes: 2), () {
        doPullNotFound();
      });
    }

    print("_pubkeys length ${_pubkeys.length}");
    var wotText = _pubkeys.keys.join(",");
    sharedPreferences.setString(genKey(pubkey), wotText);
  }

  void clear() {
    _pubkeys.clear();
  }
}
