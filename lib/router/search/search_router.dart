import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/event/event_list_component.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:sqflite/utils/utils.dart';

import '../../client/event_kind.dart' as kind;
import '../../client/filter.dart';
import '../../client/nip19/bech32.dart';
import '../../main.dart';

class SearchRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SearchRouter();
  }
}

class _SearchRouter extends CustState<SearchRouter> {
  TextEditingController controller = TextEditingController();

  @override
  Widget doBuild(BuildContext context) {
    // if (events.isEmpty) {
    //   return Container(
    //     child: Center(
    //       child: Text("SEARCH"),
    //     ),
    //   );
    // }
    return Scaffold(
      appBar: AppBar(
        title: Text("Search"),
      ),
      body: Container(
        child: Column(children: [
          Container(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "npub or hex",
              ),
              onEditingComplete: onEditingComplete,
            ),
          ),
          Expanded(
              child: Container(
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                var event = events[index];
                return EventListComponent(event: event);
              },
              itemCount: events.length,
            ),
          )),
        ]),
      ),
    );
  }

  String? subscribeId;

  List<Event> events = [];

  @override
  Future<void> onReady(BuildContext context) async {}

  void subscribe(List<String>? authors) {
    if (subscribeId != null) {
      unSubscribe();
    }
    subscribeId = generatePrivateKey();

    events = [];
    var filter = Filter(kinds: [kind.EventKind.TEXT_NOTE], authors: authors);
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
    nostr!.pool.unsubscribe(subscribeId!);
    subscribeId = null;
  }

  void onEditingComplete() {
    hideKeyBoard();

    var value = controller.text;
    value = value.trim();
    List<String>? authors;
    if (StringUtil.isNotBlank(value) && value.indexOf("npub") == 0) {
      try {
        var result = Nip19.decodePubKey(value);
        authors = [result];
      } catch (e) {
        log(e.toString());
        // TODO handle error
        return;
      }
    }
    subscribe(authors);
  }

  void hideKeyBoard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
