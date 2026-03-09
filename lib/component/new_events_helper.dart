import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_box_list.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';

import '../router/feeds/feed_page_helper.dart';
import '../util/load_more_event.dart';

mixin NewEventsHelper<T extends StatefulWidget>
    on State<T>, PenddingEventsLaterFunction {
  // eventBox for all events, including the new events and old events
  EventBoxList eventBoxList = EventBoxList();

  EventMemBox oldEventBox = EventMemBox();

  // the events that are waiting for handling later method
  List<Event> penddingNewEvents = [];

  // the events after later mathod and waiting for adding to eventBox
  EventMemBox penddingNewEventBox = EventMemBox(sortAfterAdd: false);

  void initEventBoxList() {
    eventBoxList.addBox(oldEventBox);
  }

  void laterCallback(l) {
    var addSuccess = false;
    if (penddingEvents.isNotEmpty) {
      addSuccess = oldEventBox.addList(penddingEvents);
    }

    if (penddingNewEvents.isNotEmpty) {
      for (var e in penddingNewEvents) {
        if (eventBoxList.getById(e.id) == null) {
          addSuccess = true;
          penddingNewEventBox.add(e);
        }
      }
      penddingNewEvents.clear();
    }

    if (addSuccess) {
      setState(() {});
    }
  }

  int? megerNewEvents() {
    if (penddingNewEventBox.isEmpty()) {
      return null;
    }
    var penddingNewEventsLength = penddingNewEventBox.length();
    penddingNewEventBox.sort();
    var newestEvent = penddingNewEventBox.newestEvent;
    if (newestEvent == null) {
      return null;
    }
    var newuntil = newestEvent.createdAt;
    var tempEventBox = EventMemBox();
    tempEventBox.addBox(penddingNewEventBox);
    penddingNewEventBox.clear();
    eventBoxList.addEventBoxToFirst(tempEventBox);

    if (penddingNewEventsLength >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        jumpTo(penddingNewEventsLength);
      });
    }

    setState(() {});
    return newuntil;
  }

  void clearData() {
    eventBoxList.clear();
    // must add oldEventBox again, because eventBoxList.clear() will clear all boxes in eventBoxList, including oldEventBox
    eventBoxList.addBox(oldEventBox);
    penddingEvents.clear();
    penddingNewEvents.clear();
    penddingNewEventBox.clear();
  }

  void jumpTo(int index);
}
