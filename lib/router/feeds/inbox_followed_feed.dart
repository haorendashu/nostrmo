import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/event_box_list.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/relay/relay.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/data/feed_data.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:nostrmo/router/feeds/feed_page_helper.dart';
import 'package:nostrmo/util/load_more_event.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../component/event/event_list_component.dart';
import '../../component/new_notes_updated_component.dart';
import '../../component/placeholder/event_list_placeholder.dart';
import '../../consts/base.dart';
import '../../main.dart';

class InboxFollowedFeed extends StatefulWidget {
  FeedData feedData;

  int feedIndex;

  InboxFollowedFeed(this.feedData, this.feedIndex);

  @override
  State<StatefulWidget> createState() {
    return _InboxFollowedFeed();
  }
}

class _InboxFollowedFeed extends KeepAliveCustState<InboxFollowedFeed>
    with LoadMoreEvent, PenddingEventsLaterFunction, FeedPageHelper {
  // eventBox for all events, including the new events and old events
  EventBoxList eventBoxList = EventBoxList();

  EventMemBox oldEventBox = EventMemBox();

  // the events that are waiting for handling later method
  List<Event> penddingNewEvents = [];

  // the events after later mathod and waiting for adding to eventBox
  EventMemBox penddingNewEventBox = EventMemBox(sortAfterAdd: false);

  final ItemScrollController itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ScrollOffsetListener scrollOffsetListener =
      ScrollOffsetListener.create();

  List<String> queryHashTagList = [];
  List<String> queryPubKeyList = [];

  @override
  void initState() {
    super.initState();

    eventBoxList.addBox(oldEventBox);

    bindLoadMoreItemScroll(itemPositionsListener);
    indexProvider.setFeedScrollController(
        widget.feedIndex, itemScrollController);

    List<String> hashTagList = [];
    List<String> pubKeyList = [];
    contactListProvider.list().forEach((contact) {
      pubKeyList.add(contact.publicKey);
    });
    hashTagList.addAll(contactListProvider.tagList());

    queryHashTagList = hashTagList;
    queryPubKeyList = pubKeyList;
  }

  @override
  Widget doBuild(BuildContext context) {
    if (eventBoxList.isEmpty()) {
      return EventListPlaceholder();
    }
    var themeData = Theme.of(context);

    preBuild();

    Widget main = EventListComponent(
      eventBoxList,
      itemScrollController,
      scrollOffsetController,
      itemPositionsListener,
      scrollOffsetListener,
      onRefresh: refresh,
    );

    main = Stack(
      alignment: Alignment.center,
      children: [
        main,
        Positioned(
          top: Base.BASE_PADDING,
          child: penddingNewEventBox.length() > 0
              ? NewNotesUpdatedComponent(
                  num: penddingNewEventBox.length(),
                  onTap: megerNewEvents,
                )
              : Container(),
        ),
      ],
    );

    return main;
  }

  @override
  void doQuery() {
    preQuery();

    List<Map<String, dynamic>> filters = [];

    var baseFilter = Filter(
      kinds: getEventKinds(),
      until: until,
      since: until! - 60 * 60 * 5,
      limit: 10000,
    );

    if (queryPubKeyList.isNotEmpty) {
      var filter = baseFilter.toJson();
      filter["authors"] = queryPubKeyList;
      filters.add(filter);
    }

    if (queryHashTagList.isNotEmpty) {
      var filter = baseFilter.toJson();
      filter["#t"] = queryHashTagList;
      filters.add(filter);
    }

    if (filters.isEmpty) {
      log("SyncFeed's filters is empty");
      return;
    }

    nostr!.query(filters, (e) {
      if (!isSupportedEventType(e)) {
        return;
      }

      if (eventBoxList.isEmpty()) {
        laterTimeMS = 200;
      } else {
        laterTimeMS = 500;
      }

      later(e, laterCallback, null);
    });
  }

  @override
  EventMemBox getEventBox() {
    return eventBoxList;
  }

  @override
  FeedData getFeedData() {
    return widget.feedData;
  }

  @override
  Future<void> onReady(BuildContext context) async {
    until ??= getOrSetUntilTime();
    pullNewEvents(until!);
    doQuery();
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

  String? pullNewEventSubscriptionId;

  void pullNewEvents(int until) {
    if (pullNewEventSubscriptionId != null) {
      nostr!.unsubscribe(pullNewEventSubscriptionId!);
    }
    pullNewEventSubscriptionId = StringUtil.rndNameStr(14);
    log("pullNewEventSubscriptionId $pullNewEventSubscriptionId");

    List<Map<String, dynamic>> filters = [];

    var baseFilter = Filter(
      kinds: getEventKinds(),
      since: until, // using until as since query new events
      limit: 10000,
    );

    if (queryPubKeyList.isNotEmpty) {
      var filter = baseFilter.toJson();
      filter["authors"] = queryPubKeyList;
      filters.add(filter);
    }

    if (queryHashTagList.isNotEmpty) {
      var filter = baseFilter.toJson();
      filter["#t"] = queryHashTagList;
      filters.add(filter);
    }

    if (filters.isEmpty) {
      log("InBoxFollowed's filters is empty");
      return;
    }

    nostr!.subscribe(filters, (e) {
      if (!isSupportedEventType(e)) {
        return;
      }

      penddingNewEvents.add(e);

      later(null, laterCallback, null);
    }, relayTypes: [RelayType.NORMAL], id: pullNewEventSubscriptionId);
  }

  void refresh() {
    until = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    updateUntilTime(until!);

    eventBoxList.clear();
    // must add oldEventBox again, because eventBoxList.clear() will clear all boxes in eventBoxList, including oldEventBox
    eventBoxList.addBox(oldEventBox);
    penddingEvents.clear();
    penddingNewEventBox.clear();

    pullNewEvents(until!);
    doQuery();

    setState(() {});
  }

  void megerNewEvents() {
    if (penddingNewEventBox.isEmpty()) {
      return;
    }
    var penddingNewEventsLength = penddingNewEventBox.length();
    penddingNewEventBox.sort();
    var newestEvent = penddingNewEventBox.newestEvent;
    if (newestEvent == null) {
      return;
    }
    var newuntil = newestEvent.createdAt;
    var tempEventBox = EventMemBox();
    tempEventBox.addBox(penddingNewEventBox);
    penddingNewEventBox.clear();
    eventBoxList.addEventBoxToFirst(tempEventBox);

    if (penddingNewEventsLength >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        itemScrollController.jumpTo(index: penddingNewEventsLength);
      });
    }

    updateUntilTime(newuntil);
    setState(() {});
  }
}
