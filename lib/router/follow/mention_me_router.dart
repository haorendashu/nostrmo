import 'package:flutter/material.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/data/event_mem_box.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/mention_me_provider.dart';
import 'package:nostrmo/util/load_more_event.dart';
import 'package:provider/provider.dart';

import '../../client/event_kind.dart' as kind;
import '../../client/filter.dart';
import '../../component/event/event_list_component.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';

class MentionMeRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MentionMeRouter();
  }
}

class _MentionMeRouter extends State<MentionMeRouter> with LoadMoreEvent {
  ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
  }

  @override
  Widget build(BuildContext context) {
    var _mentionMeProvider = Provider.of<MentionMeProvider>(context);
    var eventBox = _mentionMeProvider.eventBox;
    var events = eventBox.all();
    if (events.isEmpty) {
      return Container(
        child: Center(
          child: Text("Mention Me"),
        ),
      );
    }
    indexProvider.setMentionedScrollController(_controller);
    preBuild();

    return Container(
      child: ListView.builder(
        controller: _controller,
        itemBuilder: (BuildContext context, int index) {
          var event = events[index];
          return EventListComponent(
            event: event,
          );
        },
        itemCount: events.length,
      ),
    );
  }

  @override
  void doQuery() {
    preQuery();
    mentionMeProvider.doQuery(until: until);
  }

  @override
  EventMemBox getEventBox() {
    return mentionMeProvider.eventBox;
  }
}
