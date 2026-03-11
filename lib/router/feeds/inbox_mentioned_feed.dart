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
import '../../component/new_events_helper.dart';
import '../../component/new_notes_updated_component.dart';
import '../../component/placeholder/event_list_placeholder.dart';
import '../../consts/base.dart';
import '../../main.dart';

class InboxMentionedFeed extends StatefulWidget {
  FeedData feedData;

  int feedIndex;

  InboxMentionedFeed(this.feedData, this.feedIndex);

  @override
  State<StatefulWidget> createState() {
    return _InboxMentionedFeed();
  }
}

class _InboxMentionedFeed extends KeepAliveCustState<InboxMentionedFeed>
    with
        LoadMoreEvent,
        PenddingEventsLaterFunction,
        FeedPageHelper,
        NewEventsHelper<InboxMentionedFeed> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ScrollOffsetListener scrollOffsetListener =
      ScrollOffsetListener.create();

  @override
  void initState() {
    super.initState();
    initEventBoxList();

    bindLoadMoreItemScroll(itemPositionsListener);
    indexProvider.setFeedScrollController(
        widget.feedIndex, itemScrollController);
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
                  onTap: () {
                    var newuntil = megerNewEvents();
                    if (newuntil != null) {
                      updateUntilTime(newuntil);
                    }
                  },
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

    var baseFilter = Filter(
      kinds: getEventKinds(),
      until: until,
      since: until! - 60 * 60 * 24 * 30, // default query 30 days data
      limit: 10000,
      p: [nostr!.publicKey],
    );

    nostr!.query([baseFilter.toJson()], (e) {
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

  String? pullNewEventSubscriptionId;

  void pullNewEvents(int until) {
    if (pullNewEventSubscriptionId != null) {
      nostr!.unsubscribe(pullNewEventSubscriptionId!);
    }
    pullNewEventSubscriptionId = StringUtil.rndNameStr(14);
    log("pullNewEventSubscriptionId $pullNewEventSubscriptionId");

    var baseFilter = Filter(
      kinds: getEventKinds(),
      since: until, // using until as since query new events
      limit: 10000,
      p: [nostr!.publicKey],
    );

    nostr!.subscribe([baseFilter.toJson()], (e) {
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

    clearData();

    pullNewEvents(until!);
    doQuery();

    setState(() {});
  }

  @override
  void jumpTo(int index) {
    itemScrollController.jumpTo(index: index);
  }
}
