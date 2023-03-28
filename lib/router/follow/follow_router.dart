import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/event_mem_box.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/follow_event_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../component/event/event_list_component.dart';
import '../../util/load_more_event.dart';

class FollowRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FollowRouter();
  }
}

class _FollowRouter extends State<FollowRouter> with LoadMoreEvent {
  ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
  }

  @override
  Widget build(BuildContext context) {
    var _followEventProvider = Provider.of<FollowEventProvider>(context);
    var eventBox = _followEventProvider.eventBox;
    var events = eventBox.all();
    if (events.isEmpty) {
      return Container(
        child: Center(
          child: Text("FOLLOW"),
        ),
      );
    }
    indexProvider.setFollowScrollController(_controller);
    preBuild();

    var main = ListView.builder(
      controller: _controller,
      itemBuilder: (BuildContext context, int index) {
        var event = events[index];
        return GestureDetector(
          onTap: () {
            // print(event.toJson());
            RouterUtil.router(context, RouterPath.THREAD_DETAIL, event);
          },
          child: EventListComponent(event: event),
        );
      },
      itemCount: events.length,
    );

    // return MediaQuery.removePadding(
    //   context: context,
    //   removeTop: true,
    //   child: main,
    // );
    return RefreshIndicator(
      onRefresh: () async {
        followEventProvider.refresh();
      },
      child: main,
    );
  }

  @override
  void doQuery() {
    preQuery();
    followEventProvider.doQuery(until: until);
  }

  @override
  EventMemBox getEventBox() {
    return followEventProvider.eventBox;
  }
}
