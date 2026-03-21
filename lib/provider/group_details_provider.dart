import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/utils/relay_addr_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/main.dart';

class GroupDetailsProvider extends ChangeNotifier {
  Map<String, RelayGroupDetail> relayGroupDetailMap = {};

  // split groups to relays
  // relay - group => 1 - n
  void handlePull(List<GroupIdentifier> groupIdentifiers, bool add) {
    Map<String, RelayGroupDetail> changedRelayGroupDetails = {};

    for (var groupIdentifier in groupIdentifiers) {
      var host = groupIdentifier.host;
      var groupId = groupIdentifier.groupId;
      var relayGroupDetail = relayGroupDetailMap[host];
      if (relayGroupDetail == null) {
        relayGroupDetail = RelayGroupDetail(host);
        relayGroupDetailMap[host] = relayGroupDetail;
      }

      if (!relayGroupDetail.groupIds.contains(groupId)) {
        if (add) {
          relayGroupDetail.groupIds.add(groupId);
        } else {
          relayGroupDetail.groupIds.remove(groupId);
        }

        if (changedRelayGroupDetails[relayGroupDetail.host] == null) {
          changedRelayGroupDetails[relayGroupDetail.host] = relayGroupDetail;
        }
      }
    }

    for (var entry in changedRelayGroupDetails.entries) {
      var relayGroupDetail = entry.value;
      relaySubscribe(relayGroupDetail);
    }
  }

  void beginPull(List<GroupIdentifier> groupIdentifiers) {
    handlePull(groupIdentifiers, true);
  }

  void removePull(List<GroupIdentifier> groupIdentifiers) {
    handlePull(groupIdentifiers, false);
  }

  void relaySubscribe(RelayGroupDetail relayGroupDetail) {
    var relays = [relayGroupDetail.host];

    if (relayGroupDetail.pullIds.isNotEmpty) {
      relayUnsubscribe(relayGroupDetail);
    }

    List<Map<String, dynamic>> filters = [];
    for (var groupId in relayGroupDetail.groupIds) {
      {
        var filter = Filter(
          kinds: supportChatKinds,
          limit: 10,
        );
        var filterJsonMap = filter.toJson();
        filterJsonMap["#h"] = [groupId];

        filters.add(filterJsonMap);
      }

      {
        var filter = Filter(
          kinds: supportNoteKinds,
          limit: 10,
        );
        var filterJsonMap = filter.toJson();
        filterJsonMap["#h"] = [groupId];

        filters.add(filterJsonMap);
      }
    }

    for (var filter in filters) {
      var pullIds = StringUtil.rndNameStr(12);
      relayGroupDetail.pullIds.add(pullIds);

      nostr!.subscribe(
        [filter],
        (e) {
          onEvent(relayGroupDetail, e);
        },
        id: pullIds,
        targetRelays: relays,
        relayTypes: [],
        sendAfterAuth: true,
      );
    }
  }

  void relayUnsubscribe(RelayGroupDetail relayGroupDetail) {
    for (var pullId in relayGroupDetail.pullIds) {
      nostr!.unsubscribe(pullId);
    }
    relayGroupDetail.pullIds.clear();
  }

  void queryGroupEvents(
    GroupIdentifier groupIdentifier,
    int until,
    List<int> supportKinds,
  ) {
    var host = groupIdentifier.host;
    var relayGroupDetail = relayGroupDetailMap[host];
    if (relayGroupDetail == null) {
      relayGroupDetail = RelayGroupDetail(host);
      relayGroupDetailMap[host] = relayGroupDetail;
    }
    var relays = [host];

    var filter = Filter(
      kinds: supportKinds,
      limit: 100,
      until: until,
    );
    var filterJsonMap = filter.toJson();
    filterJsonMap["#h"] = [groupIdentifier.groupId];

    nostr!.query(
      [filterJsonMap],
      (e) {
        onEvent(relayGroupDetail!, e);
      },
      targetRelays: relays,
      relayTypes: [],
      sendAfterAuth: true,
    );
  }

  void onEvent(RelayGroupDetail relayGroupDetail, Event e) {
    String? groupId;
    for (var tag in e.tags) {
      if (tag is List && tag.length > 1) {
        var k = tag[0];
        var v = tag[1];

        if (k == "h") {
          groupId = v;
          break;
        }
      }
    }

    if (StringUtil.isBlank(groupId)) {
      return;
    }

    Map<String, EventMemBox>? boxMap;
    if (GroupDetailsProvider.supportNoteKinds.contains(e.kind)) {
      boxMap = relayGroupDetail.notesBoxMap;
    } else if (GroupDetailsProvider.supportChatKinds.contains(e.kind)) {
      boxMap = relayGroupDetail.chatsBoxMap;
    }

    if (boxMap == null) {
      return;
    }

    var eventBox = boxMap[groupId];
    if (eventBox == null) {
      eventBox = EventMemBox();
      boxMap[groupId!] = eventBox;
    }

    if (eventBox.add(e)) {
      // add success
      eventBox = EventMemBox.clone(eventBox);
      boxMap[groupId!] = eventBox;
      notifyListeners();
    }
    notifyListeners();
  }

  bool isGroupNote(Event e) {
    return e.kind == EventKind.GROUP_NOTE || e.kind == EventKind.COMMENT;
  }

  bool isGroupChat(Event e) {
    return e.kind == EventKind.GROUP_CHAT_MESSAGE;
  }

  EventMemBox? getChatsEventBox(GroupIdentifier groupIdentifier) {
    var detail = relayGroupDetailMap[groupIdentifier.host];
    if (detail != null) {
      return detail.chatsBoxMap[groupIdentifier.groupId];
    }

    return null;
  }

  EventMemBox? getNotesEventBox(GroupIdentifier groupIdentifier) {
    var detail = relayGroupDetailMap[groupIdentifier.host];
    if (detail != null) {
      return detail.notesBoxMap[groupIdentifier.groupId];
    }

    return null;
  }

  static List<int> supportEventKinds = [
    EventKind.GROUP_NOTE,
    EventKind.COMMENT,
    EventKind.GROUP_CHAT_MESSAGE,
  ];

  static List<int> supportNoteKinds = [
    EventKind.GROUP_NOTE,
    EventKind.COMMENT,
  ];

  static List<int> supportChatKinds = [
    EventKind.GROUP_CHAT_MESSAGE,
  ];

  static const int PREVIOUS_LENGTH = 5;

  static List<String> getTimelinePrevious(
    EventMemBox eventBox, {
    int length = PREVIOUS_LENGTH,
  }) {
    // FIXME sometimes with previous, can't send msg to nip29 relays, some temp hide these codes
    // var list = eventBox.all();
    // var listLength = list.length;

    // List<String> previous = [];

    // for (var i = 0; i < PREVIOUS_LENGTH; i++) {
    //   var index = listLength - i - 1;
    //   if (index < 0) {
    //     break;
    //   }

    //   var event = list[index];
    //   var idSubStr = event.id.substring(0, 8);
    //   previous.add(idSubStr);
    // }

    // return previous;
    return [];
  }
}

class RelayGroupDetail {
  String host;

  List<String> groupIds = [];

  RelayGroupDetail(this.host);

  Map<String, EventMemBox> notesBoxMap = {};

  Map<String, EventMemBox> chatsBoxMap = {};

  List<String> pullIds = [];
}
