import 'package:flutter/material.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/event/event_list_component.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/component/placeholder/event_list_placeholder.dart';
import 'package:nostrmo/consts/event_kind_type.dart';
import 'package:nostrmo/data/feed_data.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/feeds/feed_page_helper.dart';
import 'package:nostrmo/util/load_more_event.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

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
    with LoadMoreEvent, PenddingEventsLaterFunction, FeedPageHelper {
  int? _since;

  int? _until;

  ScrollController scrollController = ScrollController();

  ListObserverController? listObserverController;

  List<String> relays = [];

  @override
  void initState() {
    super.initState();

    relays = [];
    for (var feedSource in getFeedData().sources) {
      if (feedSource.length > 1 &&
          feedSource[0] == FeedSourceType.FEED_TYPE &&
          feedSource[1] is String) {
        relays.add(feedSource[1]);
      }
    }

    bindLoadMoreScroll(scrollController);
    listObserverController =
        ListObserverController(controller: scrollController);

    indexProvider.setFeedScrollController(widget.feedIndex, scrollController);
  }

  EventMemBox eventBox = EventMemBox();

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
    }, targetRelays: relays);
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
      listObserverController!,
      onRefresh: () {
        _until = null;
        _since = null;
        doQuery();
      },
    );
  }

  @override
  FeedData getFeedData() {
    return widget.feedData;
  }
}
