import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/feed_data_type.dart';
import 'package:nostrmo/router/feeds/feed_page_helper.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import '../../component/event/event_list_component.dart';
import '../../component/new_notes_updated_component.dart';
import '../../component/placeholder/event_list_placeholder.dart';
import '../../consts/event_kind_type.dart';
import '../../data/feed_data.dart';
import '../../main.dart';
import '../../util/load_more_event.dart';
import 'relay_feed.dart';

class SyncFeed extends StatefulWidget {
  FeedData feedData;

  int feedIndex;

  SyncFeed(this.feedData, this.feedIndex);

  @override
  State<StatefulWidget> createState() {
    return _SyncFeed();
  }
}

class _SyncFeed extends KeepAliveCustState<SyncFeed>
    with LoadMoreEvent, PenddingEventsLaterFunction, FeedPageHelper {
  EventMemBox eventBox = EventMemBox();

  List<Event> penddingNewEvents = [];

  EventMemBox newEventBox = EventMemBox();

  ListObserverController? listObserverController;

  ScrollController scrollController = ScrollController();

  List<String> queryHashTagList = [];
  List<String> queryPubKeyList = [];

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(scrollController);
    listObserverController =
        ListObserverController(controller: scrollController);

    indexProvider.setFeedScrollController(widget.feedIndex, scrollController);

    List<String> hashTagList = [];
    List<String> pubKeyList = [];
    for (var feedData in getFeedData().datas) {
      if (feedData.length > 1) {
        var feedType = feedData[0];
        var feedDataValue = feedData[1];

        if (feedDataValue is String) {
          if (feedType == FeedDataType.HASH_TAG) {
            hashTagList.add(feedDataValue);
          } else if (feedType == FeedDataType.PUBKEY) {
            pubKeyList.add(feedDataValue);
          }
        }
      }
    }

    queryHashTagList = hashTagList;
    queryPubKeyList = pubKeyList;
  }

  @override
  void dispose() {
    disposeLater();
    super.dispose();

    if (nostr != null && pullNewEventSubscriptionId != null) {
      nostr!.unsubscribe(pullNewEventSubscriptionId!);
    }
  }

  @override
  void doQuery() {
    preQuery();

    List<Map<String, dynamic>> filters = [];

    var baseFilter = Filter(
      kinds: getEventKinds(),
      until: until,
      limit: queryLimit,
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

    if (until != null) {
      syncService.checkOrSyncOldData(until!);
    }

    nostr!.query(filters, (e) {
      if (!isSupportedEventType(e)) {
        return;
      }

      if (eventBox.isEmpty()) {
        laterTimeMS = 200;
      } else {
        laterTimeMS = 500;
      }

      later(e, laterCallback, null);
    }, relayTypes: RelayType.CACHE_AND_LOCAL);
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
      limit: queryLimit,
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

    nostr!.subscribe(filters, (e) {
      if (!isSupportedEventType(e)) {
        return;
      }

      penddingNewEvents.add(e);

      later(null, laterCallback, null);
    }, relayTypes: RelayType.CACHE_AND_LOCAL, id: pullNewEventSubscriptionId);
  }

  void megerNewEvents() {
    if (newEventBox.isEmpty()) {
      return;
    }
    var oldFirstEvent = eventBox.newestEvent;
    eventBox.addList(newEventBox.all());
    newEventBox.clear();

    var allList = eventBox.all();
    var length = allList.length;
    var index = 0;
    for (; index < length; index++) {
      var e = allList[index];
      if (oldFirstEvent != null && oldFirstEvent.id == e.id) {
        break;
      }
    }
    if (index < length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        listObserverController!.jumpTo(index: index);
      });
    }

    setState(() {});
  }

  void laterCallback(l) {
    var addSuccess = false;
    if (penddingEvents.isNotEmpty) {
      addSuccess = eventBox.addList(penddingEvents);
    }

    if (penddingNewEvents.isNotEmpty) {
      List<Event> list = [];
      for (var newEvent in penddingNewEvents) {
        // also check if the event is already in the eventBox
        if (eventBox.getById(newEvent.id) == null) {
          list.add(newEvent);
        }
      }
      if (newEventBox.addList(list)) {
        addSuccess = true;
      }
      penddingNewEvents.clear();
    }

    if (addSuccess) {
      setState(() {});
    }
  }

  @override
  EventMemBox getEventBox() {
    return eventBox;
  }

  @override
  Future<void> onReady(BuildContext context) async {
    until ??= getOrSetUntilTime();
    pullNewEvents(until!);
    doQuery();

    syncService.addSyncCompleteCallback(syncCompleteCallback);
  }

  void syncCompleteCallback() {
    print("syncCompleteCallback");
    var newestEvent = eventBox.newestEvent;
    if (newestEvent != null) {
      until = newestEvent.createdAt;
      updateUntilTime(until!);
    }
  }

  @override
  Widget doBuild(BuildContext context) {
    if (eventBox.isEmpty()) {
      return EventListPlaceholder();
    }
    var themeData = Theme.of(context);

    preBuild();

    Widget main = EventListComponent(
      eventBox.all(),
      scrollController,
      listObserverController!,
      onRefresh: refresh,
    );

    main = Stack(
      alignment: Alignment.center,
      children: [
        main,
        Positioned(
          top: Base.BASE_PADDING,
          child: newEventBox.length() > 0
              ? NewNotesUpdatedComponent(
                  num: newEventBox.length(),
                  onTap: megerNewEvents,
                )
              : Container(),
        ),
      ],
    );

    return main;
  }

  void refresh() {
    until = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    updateUntilTime(until!);

    eventBox.clear();
    newEventBox.clear();
    penddingEvents.clear();
    penddingNewEvents.clear();

    pullNewEvents(until!);
    doQuery();

    setState(() {});
  }

  @override
  FeedData getFeedData() {
    return widget.feedData;
  }
}
