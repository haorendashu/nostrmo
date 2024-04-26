import 'dart:convert';
import 'dart:developer';

import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/client/nip02/cust_contact_list.dart';
import 'package:nostrmo/client/nip04/nip04.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:pointycastle/export.dart';

import '../nip02/contact.dart';

class FollowSet extends CustContactList {
  String dTag;

  String? title;

  Map<String, Contact> _publicContacts;
  Map<String, int> _publicFollowedTags;
  Map<String, int> _publicFollowedCommunitys;
  Map<String, Contact> _privateContacts;
  Map<String, int> _privateFollowedTags;
  Map<String, int> _privateFollowedCommunitys;

  int createdAt;

  FollowSet(
    this.dTag,
    Map<String, Contact> contacts,
    Map<String, int> followedTags,
    Map<String, int> followedCommunitys,
    this._publicContacts,
    this._publicFollowedTags,
    this._publicFollowedCommunitys,
    this._privateContacts,
    this._privateFollowedTags,
    this._privateFollowedCommunitys,
    this.createdAt, {
    this.title,
  }) : super(
          contacts: contacts,
          followedTags: followedTags,
          followedCommunitys: followedCommunitys,
        );

  factory FollowSet.fromEvent(Event e, ECDHBasicAgreement agreement) {
    Map<String, Contact> contacts = {};
    Map<String, int> followedTags = {};
    Map<String, int> followedCommunitys = {};

    Map<String, Contact> publicContacts = {};
    Map<String, int> publicFollowedTags = {};
    Map<String, int> publicFollowedCommunitys = {};

    Map<String, Contact> privateContacts = {};
    Map<String, int> privateFollowedTags = {};
    Map<String, int> privateFollowedCommunitys = {};

    CustContactList.getContactInfoFromTags(
        e.tags, publicContacts, publicFollowedTags, publicFollowedCommunitys);
    String dTag = "";
    String? title;
    for (var tag in e.tags) {
      if (tag is List && tag.length > 1) {
        var k = tag[0];
        var v = tag[1];

        if (k == "d") {
          dTag = v;
        } else if (k == "title") {
          title = v;
        }
      }
    }

    if (StringUtil.isNotBlank(e.content)) {
      try {
        var contentSource = NIP04.decrypt(e.content, agreement, e.pubkey);
        var jsonObj = jsonDecode(contentSource);
        if (jsonObj is List) {
          CustContactList.getContactInfoFromTags(jsonObj, privateContacts,
              privateFollowedTags, privateFollowedCommunitys);
        }
      } catch (e) {
        // sometimes would decode fail
      }
    }

    contacts.addAll(publicContacts);
    contacts.addAll(privateContacts);
    followedTags.addAll(publicFollowedTags);
    followedTags.addAll(privateFollowedTags);
    followedCommunitys.addAll(publicFollowedCommunitys);
    followedCommunitys.addAll(privateFollowedCommunitys);

    return FollowSet(
      dTag,
      contacts,
      followedTags,
      followedCommunitys,
      publicContacts,
      publicFollowedTags,
      publicFollowedCommunitys,
      privateContacts,
      privateFollowedTags,
      privateFollowedCommunitys,
      e.createdAt,
      title: title,
    );
  }

  Event toEventMap(ECDHBasicAgreement agreement, String pubkey) {
    List<dynamic> tags = [];
    if (StringUtil.isNotBlank(dTag)) {
      tags.add(["d", dTag]);
    }
    if (StringUtil.isNotBlank(title)) {
      tags.add(["title", title]);
    }
    for (Contact contact in _publicContacts.values) {
      tags.add(["p", contact.publicKey, contact.url, contact.petname]);
    }
    for (var followedTag in _publicFollowedTags.keys) {
      tags.add(["t", followedTag]);
    }
    for (var id in _publicFollowedCommunitys.keys) {
      tags.add(["a", id]);
    }

    List<dynamic> privateTags = [];
    for (Contact contact in _privateContacts.values) {
      privateTags.add(["p", contact.publicKey, contact.url, contact.petname]);
    }
    for (var followedTag in _privateFollowedTags.keys) {
      privateTags.add(["t", followedTag]);
    }
    for (var id in _privateFollowedCommunitys.keys) {
      privateTags.add(["a", id]);
    }

    var contentSource = jsonEncode(privateTags);
    var content = NIP04.encrypt(contentSource, agreement, pubkey);

    return Event(pubkey, EventKind.FOLLOW_SETS, tags, content);
  }

  List<Contact> get publicContacts {
    return _publicContacts.values.toList();
  }

  List<Contact> get privateContacts {
    return _privateContacts.values.toList();
  }

  String displayName() {
    if (StringUtil.isNotBlank(title)) {
      return title!;
    }

    return dTag;
  }

  void addPrivate(Contact contact) {
    _privateContacts[contact.publicKey] = contact;
  }

  void addPublic(Contact contact) {
    _publicContacts[contact.publicKey] = contact;
  }

  void removePrivate(String pubkey) {
    _privateContacts.remove(pubkey);
  }

  void removePublic(String pubkey) {
    _publicContacts.remove(pubkey);
  }

  bool privateFollow(String pubkey) {
    return _privateContacts[pubkey] != null;
  }

  bool publicFollow(String pubkey) {
    return _publicContacts[pubkey] != null;
  }
}
