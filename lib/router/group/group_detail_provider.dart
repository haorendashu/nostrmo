import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';

import '../../main.dart';

class GroupDetailProvider extends ChangeNotifier
    with PenddingEventsLaterFunction {
  static const int PREVIOUS_LENGTH = 5;

  late int _initTime;

  GroupIdentifier? _groupIdentifier;

  EventMemBox newNotesBox = EventMemBox(sortAfterAdd: false);

  EventMemBox notesBox = EventMemBox(sortAfterAdd: false);

  EventMemBox chatsBox = EventMemBox(sortAfterAdd: false);

  GroupDetailProvider() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  void clear() {
    _groupIdentifier = null;
    clearData();
  }

  void clearData() {
    newNotesBox.clear();
    notesBox.clear();
    chatsBox.clear();
  }

  Timer? timer;

  void startQueryTask() {
    clearTimer();

    timer = Timer.periodic(const Duration(seconds: 8), (t) {
      try {
        _queryNewEvent();
      } catch (e) {}
    });
  }

  @override
  void dispose() {
    super.dispose;
    clear();

    clearTimer();
  }

  void clearTimer() {
    if (timer != null) {
      timer!.cancel();
      timer = null;
    }
  }

  void _queryNewEvent() {
    if (_groupIdentifier != null) {
      var relays = [_groupIdentifier!.host];
      var filter = Filter(
        since: _initTime,
        kinds: supportEventKinds,
      );
      var jsonMap = filter.toJson();
      jsonMap["#h"] = [_groupIdentifier!.groupId];
      nostr!.query(
        [jsonMap],
        _onNewEvent,
        tempRelays: relays,
        onlyTempRelays: true,
        queryLocal: false,
        sendAfterAuth: true,
      );
    }
  }

  void _onNewEvent(Event e) {
    if (e.kind == EventKind.GROUP_NOTE ||
        e.kind == EventKind.GROUP_NOTE_REPLY) {
      if (newNotesBox.add(e)) {
        if (e.createdAt > _initTime) {
          _initTime = e.createdAt;
        }
        notifyListeners();
      }
    } else if (e.kind == EventKind.GROUP_CHAT_MESSAGE ||
        e.kind == EventKind.GROUP_CHAT_REPLY) {
      if (chatsBox.add(e)) {
        chatsBox.sort();
        notifyListeners();
      }
    }
  }

  void mergeNewEvent() {
    var isNotEmpty = newNotesBox.all().isNotEmpty;
    notesBox.addBox(newNotesBox);
    if (isNotEmpty) {
      newNotesBox.clear();
      notesBox.sort();
      notifyListeners();
    }
  }

  static List<int> supportEventKinds = [
    EventKind.GROUP_NOTE,
    EventKind.GROUP_NOTE_REPLY,
    EventKind.GROUP_CHAT_MESSAGE,
    EventKind.GROUP_CHAT_REPLY,
  ];

  void doQuery(int? until) {
    if (_groupIdentifier != null) {
      var relays = [_groupIdentifier!.host];
      var filter = Filter(
        until: until ?? _initTime,
        kinds: supportEventKinds,
      );
      var jsonMap = filter.toJson();
      jsonMap["#h"] = [_groupIdentifier!.groupId];
      nostr!.query(
        [jsonMap],
        onEvent,
        tempRelays: relays,
        onlyTempRelays: true,
        queryLocal: false,
        sendAfterAuth: true,
      );
    }
  }

  void onEvent(Event event) {
    later(event, (list) {
      bool noteAdded = false;
      bool chatAdded = false;

      for (var e in list) {
        if (isGroupNote(e)) {
          if (notesBox.add(e)) {
            noteAdded = true;
          }
        } else if (isGroupChat(e)) {
          if (chatsBox.add(e)) {
            chatAdded = true;
          }
        }
      }

      if (noteAdded) {
        notesBox.sort();
      }
      if (chatAdded) {
        chatsBox.sort();
      }

      if (noteAdded || chatAdded) {
        // update ui
        notifyListeners();
      }
    }, null);
  }

  bool isGroupNote(Event e) {
    return e.kind == EventKind.GROUP_NOTE ||
        e.kind == EventKind.GROUP_NOTE_REPLY;
  }

  bool isGroupChat(Event e) {
    return e.kind == EventKind.GROUP_CHAT_MESSAGE ||
        e.kind == EventKind.GROUP_CHAT_REPLY;
  }

  void deleteEvent(Event e) {
    var id = e.id;
    if (isGroupNote(e)) {
      newNotesBox.delete(id);
      notesBox.delete(id);
      notesBox.sort();
      notifyListeners();
    } else if (isGroupChat(e)) {
      chatsBox.delete(id);
      chatsBox.sort();
      notifyListeners();
    }
  }

  void updateGroupIdentifier(GroupIdentifier groupIdentifier) {
    if (_groupIdentifier == null ||
        _groupIdentifier.toString() != groupIdentifier.toString()) {
      // clear and need to query data
      clearData();
      _groupIdentifier = groupIdentifier;
      doQuery(null);
    } else {
      _groupIdentifier = groupIdentifier;
    }
  }

  refresh() {
    clearData();
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    doQuery(null);
  }

  List<String> notesPrevious() {
    return timelinePrevious(notesBox);
  }

  List<String> chatsPrevious() {
    return timelinePrevious(chatsBox);
  }

  List<String> timelinePrevious(
    EventMemBox box, {
    int length = PREVIOUS_LENGTH,
  }) {
    var list = box.all();
    var listLength = list.length;

    List<String> previous = [];

    for (var i = 0; i < PREVIOUS_LENGTH; i++) {
      var index = listLength - i - 1;
      if (index < 0) {
        break;
      }

      var event = list[index];
      var idSubStr = event.id.substring(0, 8);
      previous.add(idSubStr);
    }

    return previous;
  }
}
