import 'package:flutter/material.dart';

import '../../client/event.dart';
import '../../client/event_kind.dart';
import '../../client/event_relation.dart';
import '../../data/event_mem_box.dart';
import '../../main.dart';
import '../../util/peddingevents_later_function.dart';
import '../../util/string_util.dart';
import '../../util/when_stop_function.dart';
import 'thread_detail_event.dart';

mixin ThreadRouterHelper<T extends StatefulWidget>
    on State<T>, WhenStopFunction, PenddingEventsLaterFunction {
  EventMemBox box = EventMemBox();

  GlobalKey sourceEventKey = GlobalKey();

  List<ThreadDetailEvent> rootSubList = [];

  void listToTree({bool refresh = true}) {
    // event in box had been sorted. The last one is the oldest.
    var all = box.all();
    var length = all.length;
    List<ThreadDetailEvent> _rootSubList = [];
    // key - id, value - item
    Map<String, ThreadDetailEvent> itemMap = {};
    for (var i = length - 1; i > -1; i--) {
      var event = all[i];
      var item = ThreadDetailEvent(event: event);
      itemMap[event.id] = item;
    }

    for (var i = length - 1; i > -1; i--) {
      var event = all[i];
      var relation = EventRelation.fromEvent(event);
      var item = itemMap[event.id]!;

      if (relation.replyId == null) {
        _rootSubList.add(item);
      } else {
        var replyItem = itemMap[relation.replyId];
        if (replyItem == null) {
          _rootSubList.add(item);
        } else {
          replyItem.subItems.add(item);
        }
      }
    }

    rootSubList = _rootSubList;
    for (var rootSub in rootSubList) {
      rootSub.handleTotalLevelNum(0);
    }

    if (refresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(sourceEventKey.currentContext!);
      });
      whenStop(() {
        if (sourceEventKey.currentContext != null) {
          Scrollable.ensureVisible(sourceEventKey.currentContext!);
        }
      });

      setState(() {});
    }
  }

  void onEvent(Event event) {
    if (event.kind == EventKind.ZAP && StringUtil.isBlank(event.content)) {
      return;
    }

    later(event, (list) {
      box.addList(list);
      listToTree();
      eventReactionsProvider.onEvents(list);
    }, null);
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();
  }

  onReplyCallback(Event event) {
    onEvent(event);
  }
}
