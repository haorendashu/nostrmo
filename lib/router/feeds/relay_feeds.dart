import 'package:flutter/material.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/event/event_list_component.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/component/placeholder/event_list_placeholder.dart';
import 'package:nostrmo/consts/event_kind_type.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/load_more_event.dart';

class RelayFeeds extends StatefulWidget {
  List<String> relayAddr;

  int feedIndex;

  RelayFeeds(this.relayAddr, this.feedIndex, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _RelayFeeds();
  }
}

class _RelayFeeds extends KeepAliveCustState<RelayFeeds>
    with LoadMoreEvent, PenddingEventsLaterFunction {
  int? _since;

  int? _until;

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(scrollController);

    indexProvider.setFeedScrollController(widget.feedIndex, scrollController);
  }

  EventMemBox eventBox = EventMemBox();

  @override
  void doQuery() {
    preQuery();

    _since ??= DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _until = _since;
    _since = _until! - const Duration(minutes: 30).inSeconds;

    var filter = Filter(
        kinds: EventKindType.SUPPORTED_EVENTS, since: _since!, until: _until!);
    nostr!.query([filter.toJson()], (e) {
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
    }, targetRelays: widget.relayAddr);
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
        _until = null;
        _since = null;
        doQuery();
      },
    );
  }
}
