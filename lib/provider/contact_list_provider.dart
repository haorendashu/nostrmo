import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip04/nip04.dart';
import 'package:nostrmo/client/nip51/follow_set.dart';
import 'package:nostrmo/router/tag/topic_map.dart';
import 'package:pointycastle/pointycastle.dart';

import '../../client/event_kind.dart' as kind;
import '../client/event.dart';
import '../client/event_kind.dart';
import '../client/nip02/contact.dart';
import '../client/nip02/cust_contact_list.dart';
import '../client/filter.dart';
import '../client/nostr.dart';
import '../main.dart';
import '../util/string_util.dart';
import 'data_util.dart';

class ContactListProvider extends ChangeNotifier {
  static ContactListProvider? _contactListProvider;

  Event? _event;

  String content = "";

  CustContactList? _contactList;

  Map<String, FollowSet> followSetMap = {};

  ECDHBasicAgreement? nip04Agreement;

  static ContactListProvider getInstance() {
    if (_contactListProvider == null) {
      _contactListProvider = ContactListProvider();
      // _contactListProvider!.reload();
    }
    return _contactListProvider!;
  }

  void reload({Nostr? targetNostr}) {
    targetNostr ??= nostr;

    String? pubkey;
    if (targetNostr != null) {
      pubkey = targetNostr.publicKey;
    }
    nip04Agreement = NIP04.getAgreement(targetNostr!.privateKey!);

    var str = sharedPreferences.getString(DataKey.CONTACT_LISTS);
    if (StringUtil.isNotBlank(str)) {
      var jsonMap = jsonDecode(str!);

      if (jsonMap is Map<String, dynamic>) {
        String? eventStr;
        if (StringUtil.isNotBlank(pubkey)) {
          eventStr = jsonMap[pubkey];
        } else if (jsonMap.length == 1) {
          eventStr = jsonMap.entries.first.value as String;
        }

        if (eventStr != null) {
          var eventMap = jsonDecode(eventStr);
          _contactListProvider!._event = Event.fromJson(eventMap);
          _contactListProvider!._contactList =
              CustContactList.fromJson(_contactListProvider!._event!.tags);
          _contactListProvider!.content = _contactListProvider!._event!.content;

          return;
        }
      }
    }

    _contactListProvider!._contactList = CustContactList();
  }

  void clearCurrentContactList() {
    var pubkey = nostr!.publicKey;
    var str = sharedPreferences.getString(DataKey.CONTACT_LISTS);
    if (StringUtil.isNotBlank(str)) {
      var jsonMap = jsonDecode(str!);
      if (jsonMap is Map) {
        jsonMap.remove(pubkey);

        var jsonStr = jsonEncode(jsonMap);
        sharedPreferences.setString(DataKey.CONTACT_LISTS, jsonStr);
      }
    }
  }

  var subscriptId = StringUtil.rndNameStr(16);

  void query({Nostr? targetNostr}) {
    targetNostr ??= nostr;
    subscriptId = StringUtil.rndNameStr(16);
    var filter = Filter(
        kinds: [kind.EventKind.CONTACT_LIST],
        limit: 1,
        authors: [targetNostr!.publicKey]);
    var filter1 = Filter(
        kinds: [kind.EventKind.FOLLOW_SETS],
        limit: 100,
        authors: [targetNostr.publicKey]);
    targetNostr.addInitQuery([
      filter.toJson(),
      filter1.toJson(),
    ], _onEvent, id: subscriptId);
  }

  void _onEvent(Event e) {
    if (e.kind == kind.EventKind.CONTACT_LIST) {
      if (_event == null || e.createdAt > _event!.createdAt) {
        _event = e;
        _contactList = CustContactList.fromJson(e.tags);
        content = e.content;
        _saveAndNotify();

        relayProvider.relayUpdateByContactListEvent(e);
      }
    } else if (e.kind == kind.EventKind.FOLLOW_SETS) {
      var followSet = FollowSet.fromEvent(e, nip04Agreement!);
      if (StringUtil.isBlank(followSet.dTag)) {
        return;
      }

      var oldFollowSet = followSetMap[followSet.dTag];
      if (oldFollowSet != null) {
        if (followSet.createdAt > oldFollowSet.createdAt) {
          followSetMap[followSet.dTag] = followSet;
          notifyListeners();
        }
      } else {
        followSetMap[followSet.dTag] = followSet;
        notifyListeners();
      }
    }
  }

  void _saveAndNotify({bool notify = true}) {
    var eventJsonMap = _event!.toJson();
    var eventJsonStr = jsonEncode(eventJsonMap);

    var pubkey = nostr!.publicKey;
    Map<String, dynamic>? allJsonMap;

    var str = sharedPreferences.getString(DataKey.CONTACT_LISTS);
    if (StringUtil.isNotBlank(str)) {
      allJsonMap = jsonDecode(str!);
    }
    allJsonMap ??= {};

    allJsonMap[pubkey] = eventJsonStr;
    var jsonStr = jsonEncode(allJsonMap);

    sharedPreferences.setString(DataKey.CONTACT_LISTS, jsonStr);

    if (notify) {
      notifyListeners();
      followEventProvider.metadataUpdatedCallback(_contactList);
    }
  }

  int total() {
    return _contactList!.total();
  }

  void addContact(Contact contact) {
    _contactList!.add(contact);
    _event = nostr!.sendContactList(_contactList!, content);

    _saveAndNotify();
  }

  void removeContact(String pubkey) {
    _contactList!.remove(pubkey);
    _event = nostr!.sendContactList(_contactList!, content);

    _saveAndNotify();
  }

  void updateContacts(CustContactList contactList) {
    _contactList = contactList;
    _event = nostr!.sendContactList(contactList, content);

    _saveAndNotify();
  }

  CustContactList? get contactList => _contactList;

  Iterable<Contact> list() {
    return _contactList!.list();
  }

  Contact? getContact(String pubkey) {
    return _contactList!.get(pubkey);
  }

  void clear() {
    _event = null;
    _contactList!.clear();
    content = "";
    clearCurrentContactList();

    notifyListeners();
  }

  bool containTag(String tag) {
    var list = TopicMap.getList(tag);
    if (list != null) {
      for (var t in list) {
        var exist = _contactList!.containsTag(t);
        if (exist) {
          return true;
        }
      }
      return false;
    } else {
      return _contactList!.containsTag(tag);
    }
  }

  void addTag(String tag) {
    _contactList!.addTag(tag);
    _event = nostr!.sendContactList(_contactList!, content);

    _saveAndNotify();
  }

  void removeTag(String tag) {
    _contactList!.removeTag(tag);
    _event = nostr!.sendContactList(_contactList!, content);

    _saveAndNotify();
  }

  int totalFollowedTags() {
    return _contactList!.totalFollowedTags();
  }

  Iterable<String> tagList() {
    return _contactList!.tagList();
  }

  bool containCommunity(String id) {
    return _contactList!.containsCommunity(id);
  }

  void addCommunity(String tag) {
    _contactList!.addCommunity(tag);
    _event = nostr!.sendContactList(_contactList!, content);

    _saveAndNotify();
  }

  void removeCommunity(String tag) {
    _contactList!.removeCommunity(tag);
    _event = nostr!.sendContactList(_contactList!, content);

    _saveAndNotify();
  }

  int totalfollowedCommunities() {
    return _contactList!.totalFollowedCommunities();
  }

  Iterable<String> followedCommunitiesList() {
    return _contactList!.followedCommunitiesList();
  }

  void updateRelaysContent(String relaysContent) {
    content = relaysContent;
    _event = nostr!.sendContactList(_contactList!, content);

    _saveAndNotify(notify: false);
  }

  void deleteFollowSet(String dTag) {
    followSetMap.remove(dTag);

    var filter =
        Filter(authors: [nostr!.publicKey], kinds: [EventKind.FOLLOW_SETS]);
    var filterMap = filter.toJson();
    filterMap["#d"] = [dTag];

    Map<String, int> deleted = {};
    nostr!.query([filterMap], (event) {
      if (event.kind == EventKind.FOLLOW_SETS) {
        if (deleted[event.id] == null) {
          deleted[event.id] = 1;
          log(jsonEncode(event.sources));
          log(jsonEncode(event.toJson()));
          nostr!.deleteEvent(event.id);
        }
      }
    });
    notifyListeners();
  }

  void addFollowSet(FollowSet followSet) {
    followSetMap[followSet.dTag] = followSet;
    var event = followSet.toEventMap(nip04Agreement!, nostr!.publicKey);
    nostr!.sendEvent(event);
    notifyListeners();
  }
}
