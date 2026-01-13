import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/consts/feed_data_type.dart';
import 'package:nostrmo/router/feeds/feed_page_helper.dart';

import '../../component/event/event_list_component.dart';
import '../../component/placeholder/event_list_placeholder.dart';
import '../../consts/event_kind_type.dart';
import '../../data/feed_data.dart';
import '../../main.dart';
import '../../util/load_more_event.dart';
import 'relay_feed.dart';

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
    with LoadMoreEvent, PenddingEventsLaterFunction, FeedPageHelper {
  EventMemBox eventBox = EventMemBox();

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(scrollController);

    indexProvider.setFeedScrollController(widget.feedIndex, scrollController);
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

      if (eventBox.isEmpty()) {
        laterTimeMS = 200;
      } else {
        laterTimeMS = 500;
      }

      later(e, (events) {
        var addSuccess = eventBox.addList(events);
        if (addSuccess) {
          setState(() {});
        }
      }, null);
    }, relayTypes: RelayType.CACHE_AND_LOCAL);
  }

  @override
  EventMemBox getEventBox() {
    return eventBox;
  }

  @override
  Future<void> onReady(BuildContext context) async {
    doQuery();
  }

  @override
  Widget doBuild(BuildContext context) {
    if (eventBox.isEmpty()) {
      return EventListPlaceholder();
    }

    preBuild();

    return EventListComponent(
      eventBox.all(),
      scrollController,
      onRefresh: () {
        until = null;
        eventBox.clear();
        doQuery();
      },
    );
  }

  @override
  FeedData getFeedData() {
    return widget.feedData;
  }
}
