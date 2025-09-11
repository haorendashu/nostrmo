import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip29/group_admins.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/nip29/group_members.dart';
import 'package:nostr_sdk/nip29/group_metadata.dart';
import 'package:nostr_sdk/nip29/group_object.dart';
import 'package:nostr_sdk/nip29/nip29.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/main.dart';
import 'package:nostr_sdk/utils/later_function.dart';

class GroupProvider extends ChangeNotifier with LaterFunction {
  Map<String, GroupMetadata> groupMetadatas = {};

  Map<String, GroupAdmins> groupAdmins = {};

  Map<String, GroupMembers> groupMembers = {};

  final Map<String, int> _handlingMetadataIds = {};

  final Map<String, int> _handlingAdminsIds = {};

  final Map<String, int> _handlingMembersIds = {};

  int now() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  void _markHandling(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();
    var t = now();

    _handlingMetadataIds[key] = t;
    _handlingAdminsIds[key] = t;
    _handlingMembersIds[key] = t;
  }

  void _cleanHandling(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();

    _handlingMetadataIds.remove(key);
    _handlingAdminsIds.remove(key);
    _handlingMembersIds.remove(key);
  }

  Future<void> deleteEvent(
      GroupIdentifier groupIdentifier, String eventId) async {
    await NIP29.deleteEvent(nostr!, groupIdentifier, eventId);
  }

  Future<void> editStatus(
      GroupIdentifier groupIdentifier, bool? public, bool? open) async {
    await NIP29.editStatus(nostr!, groupIdentifier, public, open);
  }

  GroupMetadata? getMetadata(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();
    var m = groupMetadatas[key];
    if (m != null) {
      return m;
    }

    var ot = _handlingMetadataIds[key];
    if (ot == null || now() - ot > 60 * 5) {
      _markHandling(groupIdentifier);
      query(groupIdentifier);
    }
    return null;
  }

  GroupAdmins? getAdmins(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();
    var m = groupAdmins[key];
    if (m != null) {
      return m;
    }

    var ot = _handlingAdminsIds[key];
    if (ot == null || now() - ot > 60 * 5) {
      _markHandling(groupIdentifier);
      query(groupIdentifier);
    }
    return null;
  }

  GroupMembers? getMembers(GroupIdentifier groupIdentifier) {
    var key = groupIdentifier.toString();
    var m = groupMembers[key];
    if (m != null) {
      return m;
    }

    var ot = _handlingMembersIds[key];
    if (ot == null || now() - ot > 60 * 5) {
      _markHandling(groupIdentifier);
      query(groupIdentifier);
    }
    return null;
  }

  Future<void> _updateMember(GroupIdentifier groupIdentifier) async {
    var membersJsonMap =
        _genFilter(groupIdentifier.groupId, EventKind.GROUP_MEMBERS);

    await nostr!.query(
      [membersJsonMap],
      (e) {
        onEvent(groupIdentifier, e);
      },
      targetRelays: [groupIdentifier.host],
      relayTypes: RelayType.ONLY_TEMP,
    );
  }

  Future<void> addMember(GroupIdentifier groupIdentifier, String pubkey) async {
    NIP29.addMember(nostr!, groupIdentifier, pubkey);

    // try to add to mem
    var key = groupIdentifier.toString();
    var members = groupMembers[key];
    if (members != null) {
      members.add(pubkey);
    }

    await _updateMember(groupIdentifier);

    notifyListeners();
  }

  Future<void> removeMember(
      GroupIdentifier groupIdentifier, String pubkey) async {
    NIP29.removeMember(nostr!, groupIdentifier, pubkey);

    // try to delete from mem
    var key = groupIdentifier.toString();
    var members = groupMembers[key];
    if (members != null) {
      members.remove(pubkey);
    }

    await _updateMember(groupIdentifier);

    notifyListeners();
  }

  Map<String, dynamic> _genFilter(String groupId, int eventKind) {
    var filter = Filter(
      kinds: [eventKind],
      limit: 1,
    );
    var jsonMap = filter.toJson();
    jsonMap["#d"] = [groupId];

    return jsonMap;
  }

  void query(GroupIdentifier groupIdentifier) {
    var metadataJsonMap =
        _genFilter(groupIdentifier.groupId, EventKind.GROUP_METADATA);
    var adminsJsonMap =
        _genFilter(groupIdentifier.groupId, EventKind.GROUP_ADMINS);
    var membersJsonMap =
        _genFilter(groupIdentifier.groupId, EventKind.GROUP_MEMBERS);

    // log(jsonEncode([metadataJsonMap, adminsJsonMap, membersJsonMap]));

    nostr!.query(
      [metadataJsonMap, adminsJsonMap, membersJsonMap],
      (e) {
        onEvent(groupIdentifier, e);
      },
      targetRelays: [groupIdentifier.host],
      relayTypes: [],
      sendAfterAuth: true,
    );
  }

  void onEvent(GroupIdentifier groupIdentifier, Event e) {
    bool updated = false;
    if (e.kind == EventKind.GROUP_METADATA) {
      updated = handleEvent(
          groupMetadatas, groupIdentifier, GroupMetadata.loadFromEvent(e));
    } else if (e.kind == EventKind.GROUP_ADMINS) {
      updated = handleEvent(
          groupAdmins, groupIdentifier, GroupAdmins.loadFromEvent(e));
    } else if (e.kind == EventKind.GROUP_MEMBERS) {
      updated = handleEvent(
          groupMembers, groupIdentifier, GroupMembers.loadFromEvent(e));
    }

    if (updated) {
      notifyListeners();
    }
  }

  bool handleEvent(
      Map map, GroupIdentifier groupIdentifier, GroupObject? groupObject) {
    var key = groupIdentifier.toString();
    if (groupObject == null) {
      return false;
    }

    if (groupObject.groupId != groupIdentifier.groupId) {
      return false;
    }

    bool updated = false;
    var object = map[key];
    if (object == null) {
      map[key] = groupObject;
      updated = true;
    } else {
      if (object is GroupObject && groupObject.createdAt > object.createdAt) {
        map[key] = groupObject;
        updated = true;
      }
    }

    return updated;
  }

  Future<void> udpateMetadata(
      GroupIdentifier groupIdentifier, GroupMetadata groupMetadata) async {
    var relays = [groupIdentifier.host];

    var tags = [];
    tags.add(["h", groupIdentifier.groupId]);
    if (StringUtil.isNotBlank(groupMetadata.name)) {
      tags.add(["name", groupMetadata.name!]);
    }
    if (StringUtil.isNotBlank(groupMetadata.picture)) {
      tags.add(["picture", groupMetadata.picture!]);
    }
    if (StringUtil.isNotBlank(groupMetadata.about)) {
      tags.add(["about", groupMetadata.about!]);
    }

    var e = Event(nostr!.publicKey, EventKind.GROUP_EDIT_METADATA, tags, "");
    var result =
        await nostr!.sendEvent(e, targetRelays: relays, relayTypes: []);
    if (result != null) {
      handleEvent(
          groupMetadatas, groupIdentifier, GroupMetadata.loadFromEvent(e));
      notifyListeners();
    }
  }

  int checkMembership(
    GroupIdentifier groupIdentifier,
    String pubkey,
  ) {
    var key = groupIdentifier.toString();
    var members = groupMembers[key];
    if (members == null) {
      print("members not fould!");
      return GroupMembership.NOT_MEMBER;
    }

    if (members.isMember(pubkey)) {
      var adminMember = groupAdmins[key];
      if (adminMember != null) {
        if (adminMember.contains(pubkey) != null) {
          return GroupMembership.ADMIN;
        }
      }

      return GroupMembership.MEMBER;
    } else {
      print("member not fould!");
      return GroupMembership.NOT_MEMBER;
    }
  }
}

class GroupMembership {
  static const int NOT_MEMBER = 0;
  static const int MEMBER = 1;
  static const int ADMIN = 2;
}
