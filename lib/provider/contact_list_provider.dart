import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/cust_nostr.dart';

import '../../client/event_kind.dart' as kind;
import '../client/cust_contact_list.dart';
import '../client/filter.dart';
import '../main.dart';
import '../util/string_util.dart';
import 'data_util.dart';

class ContactListProvider extends ChangeNotifier {
  static ContactListProvider? _contactListProvider;

  Event? _event;

  CustContactList? _contactList;

  static ContactListProvider getInstance() {
    if (_contactListProvider == null) {
      _contactListProvider = ContactListProvider();
      // _contactListProvider!.reload();
    }
    return _contactListProvider!;
  }

  void reload({CustNostr? targetNostr}) {
    targetNostr ??= nostr;

    String? pubkey;
    if (targetNostr != null) {
      pubkey = targetNostr.publicKey;
    }

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
          _contactListProvider!._event = Event.fromJson(jsonMap);
          _contactListProvider!._contactList =
              CustContactList.fromJson(_contactListProvider!._event!.tags);

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

  void query({CustNostr? targetNostr}) {
    targetNostr ??= nostr;
    subscriptId = StringUtil.rndNameStr(16);
    var filter = Filter(
        kinds: [kind.EventKind.CONTACT_LIST],
        limit: 1,
        authors: [targetNostr!.publicKey]);
    targetNostr.pool.addInitQuery([filter.toJson()], _onEvent, subscriptId);
  }

  void _onEvent(Event e) {
    if (e.kind == kind.EventKind.CONTACT_LIST) {
      if (_event == null || e.createdAt > _event!.createdAt) {
        _event = e;
        _contactList = CustContactList.fromJson(e.tags);
        _saveAndNotify();
      }
    }
  }

  void _saveAndNotify() {
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
    notifyListeners();

    followEventProvider.metadataUpdatedCallback(_contactList);
  }

  void addContact(Contact contact) {
    _contactList!.add(contact);
    _event = nostr!.sendContactList(_contactList!);

    _saveAndNotify();
  }

  void removeContact(String pubKey) {
    _contactList!.remove(pubKey);
    _event = nostr!.sendContactList(_contactList!);

    _saveAndNotify();
  }

  Iterable<Contact> list() {
    return _contactList!.list();
  }

  Contact? getContact(String pubKey) {
    return _contactList!.get(pubKey);
  }

  void clear() {
    _event = null;
    _contactList!.clear();
    clearCurrentContactList();

    notifyListeners();
  }
}
