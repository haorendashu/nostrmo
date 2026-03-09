import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/router/feeds/feed_page_helper.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../component/event/event_list_component.dart';
import '../../component/new_events_helper.dart';
import '../../component/new_notes_updated_component.dart';
import '../../component/placeholder/event_list_placeholder.dart';
import '../../consts/base.dart';
import '../../data/feed_data.dart';
import '../../main.dart';
import '../../util/load_more_event.dart';

class MentionedFeed extends StatefulWidget {
  FeedData feedData;

  int feedIndex;

  MentionedFeed(this.feedData, this.feedIndex);

  @override
  State<StatefulWidget> createState() {
    return _MentionedFeed();
  }
}

class _MentionedFeed extends KeepAliveCustState<MentionedFeed>
    with
        LoadMoreEvent,
        PenddingEventsLaterFunction,
        FeedPageHelper,
        NewEventsHelper<MentionedFeed> {
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
  void dispose() {
    super.dispose();
  }

  @override
  void doQuery() {
    preQuery();
    until ??= DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var filter = Filter(
      kinds: getEventKinds(),
      until: until,
      limit: queryLimit,
      p: [nostr!.publicKey],
    );

    nostr!.query([filter.toJson()], (e) {
      if (!isSupportedEventType(e)) {
        return;
      }

      bool isMentionedMe = false;
      e.tags.forEach((tag) {
        if (tag.length > 1 && tag[0] == 'p') {
          if (tag[1] == nostr!.publicKey) {
            isMentionedMe = true;
          }
        }
      });
      if (!isMentionedMe) {
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
  Future<void> onReady(BuildContext context) async {
    doQuery();

    if (until != null) {
      pullNewEvents(until!);
    }
  }

  void unSubscribe() {
    if (pullNewEventSubscriptionId != null) {
      nostr!.unsubscribe(pullNewEventSubscriptionId!);
    }
  }

  String? pullNewEventSubscriptionId;

  void pullNewEvents(int until) {
    unSubscribe();
    pullNewEventSubscriptionId = StringUtil.rndNameStr(14);

    var filter = Filter(
      kinds: getEventKinds(),
      until: until,
      limit: queryLimit,
      p: [nostr!.publicKey],
    );

    nostr!.subscribe([filter.toJson()], (e) {
      if (!isSupportedEventType(e)) {
        return;
      }

      penddingNewEvents.add(e);

      later(null, laterCallback, null);
    }, relayTypes: RelayType.ONLY_NORMAL, id: pullNewEventSubscriptionId);
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

  void refresh() {
    until = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    updateUntilTime(until!);

    clearData();

    pullNewEvents(until!);
    doQuery();

    setState(() {});
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
