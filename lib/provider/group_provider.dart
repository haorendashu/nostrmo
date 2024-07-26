import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/client/nip29/group_admins.dart';
import 'package:nostrmo/client/nip29/group_identifier.dart';
import 'package:nostrmo/client/nip29/group_members.dart';
import 'package:nostrmo/client/nip29/group_metadata.dart';
import 'package:nostrmo/client/nip29/group_object.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/later_function.dart';
import 'package:nostrmo/util/string_util.dart';

import '../client/filter.dart';

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

  Map<String, dynamic> _genFilter(String groupId, int eventKind) {
    var filter = Filter(
      kinds: [eventKind],
      limit: 1,
    );
    var jsonMap = filter.toJson();
    jsonMap["d"] = [groupId];

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
        // log(jsonEncode(e.toJson()));

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
      },
      tempRelays: [groupIdentifier.host],
      onlyTempRelays: true,
      queryLocal: false,
      // sendAfterAuth: true,
    );
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

  void udpateMetadata(
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
        await nostr!.sendEvent(e, tempRelays: relays, targetRelays: relays);
    if (result != null) {
      handleEvent(
          groupMetadatas, groupIdentifier, GroupMetadata.loadFromEvent(e));
    }
  }
}
