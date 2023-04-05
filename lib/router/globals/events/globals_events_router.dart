import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';

import '../../../client/event_kind.dart' as kind;
import '../../../client/filter.dart';
import '../../../component/cust_state.dart';
import '../../../component/event/event_list_component.dart';
import '../../../component/placeholder/event_list_placeholder.dart';
import '../../../consts/base.dart';
import '../../../data/event_mem_box.dart';
import '../../../main.dart';
import '../../../util/dio_util.dart';
import '../../../util/peddingevents_later_function.dart';
import '../../../util/string_util.dart';
import 'globals_event_item_component.dart';

class GlobalsEventsRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GlobalsEventsRouter();
  }
}

class _GlobalsEventsRouter extends KeepAliveCustState<GlobalsEventsRouter>
    with PenddingEventsLaterFunction {
  ScrollController scrollController = ScrollController();

  List<String> ids = [];

  EventMemBox eventBox = EventMemBox(sortAfterAdd: false);

  @override
  Widget doBuild(BuildContext context) {
    if (eventBox.isEmpty()) {
      return EventListPlaceholder(
        onRefresh: refresh,
      );
    }

    var list = eventBox.all();

    return Container(
      child: ListView.builder(
        controller: scrollController,
        itemBuilder: (context, index) {
          var event = list[index];
          return EventListComponent(event: event);
        },
        itemCount: list.length,
      ),
    );
  }

  var subscribeId = StringUtil.rndNameStr(16);

  @override
  Future<void> onReady(BuildContext context) async {
    indexProvider.setEventScrollController(scrollController);
    refresh();
  }

  Future<void> refresh() async {
    if (StringUtil.isNotBlank(subscribeId)) {
      unsubscribe();
    }

    var str = await DioUtil.getStr(Base.INDEXS_EVENTS);
    // print(str);
    if (StringUtil.isNotBlank(str)) {
      ids.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        ids.add(itf as String);
      }
    }

    var filter = Filter(ids: ids, kinds: [kind.EventKind.TEXT_NOTE]);
    nostr!.pool.subscribe([filter.toJson()], (event) {
      if (eventBox.isEmpty()) {
        laterTimeMS = 200;
      } else {
        laterTimeMS = 1000;
      }

      later(event, (list) {
        eventBox.addList(list);
        setState(() {});
      }, null);
    }, subscribeId);
  }

  void unsubscribe() {
    try {
      nostr!.pool.unsubscribe(subscribeId);
    } catch (e) {}
  }

  @override
  void dispose() {
    super.dispose();

    unsubscribe();
    disposeLater();
  }
}
