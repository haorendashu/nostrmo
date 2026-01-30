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
    with LoadMoreEvent, PenddingEventsLaterFunction, FeedPageHelper {
  EventMemBox eventBox = EventMemBox();

  List<Event> penddingNewEvents = [];

  EventMemBox newEventBox = EventMemBox();

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
    bindLoadMoreItemScroll(itemPositionsListener);
    indexProvider.setFeedScrollController(
        widget.feedIndex, itemScrollController);
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
    });
  }

  @override
  EventMemBox getEventBox() {
    return eventBox;
  }

  @override
  Future<void> onReady(BuildContext context) async {
    doQuery();
  }

  String? pullNewEventSubscriptionId;

  void pullNewEvents(int until) {
    if (pullNewEventSubscriptionId != null) {
      nostr!.unsubscribe(pullNewEventSubscriptionId!);
    }
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
    }, relayTypes: RelayType.CACHE_AND_LOCAL, id: pullNewEventSubscriptionId);
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
        itemScrollController.jumpTo(index: index);
      });
    }

    setState(() {});
  }

  @override
  Widget doBuild(BuildContext context) {
    if (eventBox.isEmpty()) {
      return EventListPlaceholder();
    }

    preBuild();

    Widget main = EventListComponent(
      eventBox.all(),
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
