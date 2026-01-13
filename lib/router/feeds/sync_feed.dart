import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/consts/feed_data_type.dart';

import '../../component/event/event_list_component.dart';
import '../../component/placeholder/event_list_placeholder.dart';
import '../../consts/event_kind_type.dart';
import '../../main.dart';
import '../../util/load_more_event.dart';
import 'relay_feeds.dart';

class SyncFeed extends StatefulWidget {
  List<dynamic> feedDatas;

  int feedIndex;

  SyncFeed(this.feedDatas, this.feedIndex);

  @override
  State<StatefulWidget> createState() {
    return _SyncFeed();
  }
}

class _SyncFeed extends KeepAliveCustState<SyncFeed>
    with LoadMoreEvent, PenddingEventsLaterFunction {
  EventMemBox eventBox = EventMemBox();

  ScrollController scrollController = ScrollController();

  List<String> queryHashTagList = [];
  List<String> queryPubKeyList = [];

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(scrollController);

    indexProvider.setFeedScrollController(widget.feedIndex, scrollController);

    List<String> hashTagList = [];
    List<String> pubKeyList = [];
    for (var feedData in widget.feedDatas) {
      if (feedData is List && feedData.length > 1) {
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
  void doQuery() {
    preQuery();

    until ??= DateTime.now().millisecondsSinceEpoch ~/ 1000;

    List<Map<String, dynamic>> filters = [];

    var baseFilter = Filter(
      kinds: EventKindType.SUPPORTED_EVENTS,
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

    for (var filter in filters) {
      print(filter);
    }

    if (filters.isEmpty) {
      log("SyncFeed's filters is empty");
      return;
    }

    nostr!.query(filters, (e) {
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
}
