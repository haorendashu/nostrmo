import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/event/event_list_component.dart';

import '../../client/event_kind.dart' as kind;
import '../../client/filter.dart';
import '../../main.dart';

class SearchRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SearchRouter();
  }
}

class _SearchRouter extends CustState<SearchRouter> {
  @override
  Widget doBuild(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        child: Center(
          child: Text("SEARCH"),
        ),
      );
    }

    return Container(
      child: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          var event = events[index];
          return EventListComponent(event: event);
        },
        itemCount: events.length,
      ),
    );
  }

  String subscribeId = generatePrivateKey();

  List<Event> events = [];

  @override
  Future<void> onReady(BuildContext context) async {
    subscribe();
  }

  void subscribe() {
    events = [];
    var filter = Filter(kinds: [kind.EventKind.TEXT_NOTE], limit: 100);
    nostr!.pool.subscribe([filter.toJson()], (event) {
      // need check if id exist
      events.add(event);
      if (events.length > 200) {
        unSubscribe();
      }
      setState(() {});
    }, subscribeId);
  }

  void unSubscribe() {
    nostr!.pool.unsubscribe(subscribeId);
  }
}
