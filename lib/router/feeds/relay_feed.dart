import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/event/event_list_component.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/component/placeholder/event_list_placeholder.dart';
import 'package:nostrmo/data/feed_data.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/feeds/feed_page_helper.dart';
import 'package:nostrmo/util/load_more_event.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../component/new_events_helper.dart';
import '../../component/new_notes_updated_component.dart';
import '../../consts/base.dart';
import '../../consts/feed_source_type.dart';

class RelayFeed extends StatefulWidget {
  FeedData feedData;

  int feedIndex;

  RelayFeed(this.feedData, this.feedIndex, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _RelayFeed();
  }
}

class _RelayFeed extends KeepAliveCustState<RelayFeed>
    with
        LoadMoreEvent,
        PenddingEventsLaterFunction,
        FeedPageHelper,
        NewEventsHelper<RelayFeed> {
  int? _since;

  int? _until;

  final ItemScrollController itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ScrollOffsetListener scrollOffsetListener =
      ScrollOffsetListener.create();

  List<String> relays = [];

  @override
  void initState() {
    super.initState();
    initEventBoxList();

    relays = [];
    for (var feedSource in getFeedData().sources) {
      if (feedSource.length > 1 &&
          feedSource[0] == FeedSourceType.FEED_TYPE &&
          feedSource[1] is String) {
        relays.add(feedSource[1]);
      }
    }

    bindLoadMoreItemScroll(itemPositionsListener);
    indexProvider.setFeedScrollController(
        widget.feedIndex, itemScrollController);
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
    );

    nostr!.subscribe([baseFilter.toJson()], (e) {
      if (!isSupportedEventType(e)) {
        return;
      }

      penddingNewEvents.add(e);

      later(null, laterCallback, null);
    }, targetRelays: relays, id: pullNewEventSubscriptionId);
  }

  @override
  void doQuery() {
    preQuery();

    _since ??= DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _until = _since;
    _since = _until! - const Duration(minutes: 30).inSeconds;

    var filter = Filter(kinds: getEventKinds(), since: _since!, until: _until!);
    nostr!.query([filter.toJson()], (e) {
      if (!isSupportedEventType(e)) {
        return;
      }

      if (eventBoxList.isEmpty()) {
        laterTimeMS = 200;
      } else {
        laterTimeMS = 500;
      }

      later(e, laterCallback, null);
    }, targetRelays: relays);
  }

  @override
  EventMemBox getEventBox() {
    return eventBoxList;
  }

  @override
  Future<void> onReady(BuildContext context) async {
    doQuery();
  }

  @override
  Widget doBuild(BuildContext context) {
    if (eventBoxList.isEmpty()) {
      return EventListPlaceholder();
    }

    preBuild();

    Widget main = EventListComponent(
      eventBoxList,
      itemScrollController,
      scrollOffsetController,
      itemPositionsListener,
      scrollOffsetListener,
      onRefresh: () {
        _until = null;
        _since = null;
        doQuery();
      },
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
  FeedData getFeedData() {
    return widget.feedData;
  }

  @override
  void jumpTo(int index) {
    itemScrollController.jumpTo(index: index);
  }
}
