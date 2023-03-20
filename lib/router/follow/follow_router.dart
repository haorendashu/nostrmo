import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/follow_event_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../component/event/event_list_component.dart';

class FollowRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FollowRouter();
  }
}

class _FollowRouter extends State<FollowRouter> {
  @override
  Widget build(BuildContext context) {
    // return Selector<FollowEventProvider, bool>(
    //   builder: (context, eventExist, widget) {
    //     if (!eventExist) {
    //       return Container(
    //         child: Center(
    //           child: Text("FOLLOW"),
    //         ),
    //       );
    //     } else {
    //       return Container(
    //         child: ListView.builder(
    //           itemBuilder: (BuildContext context, int index) {
    //             return Selector<FollowEventProvider, Event?>(
    //               builder: (context, event, widget) {
    //                 if (event == null) {
    //                   return null;
    //                 }
    //               },
    //               selector: (context, _provider) {
    //                 return _provider.getBeforeEvent(index);
    //               },
    //             );
    //           },
    //         ),
    //       );
    //     }
    //   },
    //   selector: (context, _provider) {
    //     return _provider.eventExist;
    //   },
    // );

    var _followEventProvider = Provider.of<FollowEventProvider>(context);
    var events = _followEventProvider.currentEvents;
    if (events.isEmpty) {
      return Container(
        child: Center(
          child: Text("FOLLOW"),
        ),
      );
    }
    return Container(
      child: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          var event = events[index];
          return GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.THREAD_DETAIL, event);
            },
            child: EventListComponent(event: event),
          );
        },
        itemCount: events.length,
      ),
    );
  }
}
