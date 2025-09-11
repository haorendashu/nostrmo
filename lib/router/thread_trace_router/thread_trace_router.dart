import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_relation.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostr_sdk/utils/when_stop_function.dart';
import 'package:nostrmo/component/event/event_main_component.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/thread_trace_router/event_trace_info.dart';
import 'package:nostrmo/router/thread_trace_router/thread_trace_event_component.dart';
import 'package:screenshot/screenshot.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/event/event_bitcion_icon_component.dart';
import '../../component/event_reply_callback.dart';
import '../../consts/base.dart';
import '../../consts/event_kind_type.dart';
import '../../util/router_util.dart';
import '../../util/table_mode_util.dart';
import '../thread/thread_detail_event_main_component.dart';
import '../thread/thread_detail_item_component.dart';
import '../thread/thread_detail_router.dart';
import '../thread/thread_router_helper.dart';

class ThreadTraceRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ThreadTraceRouter();
  }
}

class _ThreadTraceRouter extends State<ThreadTraceRouter>
    with PenddingEventsLaterFunction, WhenStopFunction, ThreadRouterHelper {
  // used to filter parent events
  List<EventTraceInfo> parentEventTraces = [];

  Event? sourceEvent;

  ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var arg = RouterUtil.routerArgs(context);
    if (arg == null || arg is! Event) {
      RouterUtil.back(context);
      return Container();
    }
    if (sourceEvent == null) {
      // first load
      sourceEvent = arg;
      fetchDatas();
    } else {
      if (sourceEvent!.id != arg.id) {
        // find update
        sourceEvent = arg;
        fetchDatas();
      }
    }

    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    var title = ThreadDetailRouter.getAppBarTitle(sourceEvent!);
    var appBarTitle = ThreadDetailRouter.detailAppBarTitle(
        sourceEvent!.pubkey, title, themeData);

    List<Widget> mainList = [];

    List<Widget> traceList = [];
    if (parentEventTraces.isNotEmpty) {
      var length = parentEventTraces.length;
      for (var i = 0; i < length; i++) {
        var pet = parentEventTraces[length - 1 - i];

        traceList.add(GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            RouterUtil.router(
                context, RouterPath.getThreadDetailPath(), pet.event);
          },
          child: ThreadTraceEventComponent(
            pet.event,
            textOnTap: () {
              RouterUtil.router(
                  context, RouterPath.getThreadDetailPath(), pet.event);
            },
          ),
        ));
      }
    }

    Widget mainEventWidget = ThreadTraceEventComponent(
      sourceEvent!,
      key: sourceEventKey,
      traceMode: false,
    );
    if (sourceEvent!.kind == EventKind.ZAP) {
      mainEventWidget = EventBitcionIconComponent.wrapper(mainEventWidget);
    }

    mainList.add(Container(
      color: cardColor,
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      padding: EdgeInsets.only(top: Base.BASE_PADDING_HALF),
      child: Column(
        children: [
          Stack(
            children: [
              Positioned(
                child: Container(
                  width: 2,
                  color: themeData.hintColor.withOpacity(0.25),
                ),
                top: 38,
                bottom: 0,
                left: 28,
              ),
              Column(
                children: traceList,
              ),
            ],
          ),
          mainEventWidget
        ],
      ),
    ));

    for (var item in rootSubList) {
      var totalLevelNum = item.totalLevelNum;
      var needWidth = (totalLevelNum - 1) *
              (Base.BASE_PADDING +
                  ThreadDetailItemMainComponent.BORDER_LEFT_WIDTH) +
          ThreadDetailItemMainComponent.EVENT_MAIN_MIN_WIDTH;
      if (needWidth > mediaDataCache.size.width) {
        mainList.add(SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: needWidth,
            child: ThreadDetailItemComponent(
              item: item,
              totalMaxWidth: needWidth,
              sourceEventId: sourceEvent!.id,
              sourceEventKey: sourceEventKey,
            ),
          ),
        ));
      } else {
        mainList.add(ThreadDetailItemComponent(
          item: item,
          totalMaxWidth: needWidth,
          sourceEventId: sourceEvent!.id,
          sourceEventKey: sourceEventKey,
        ));
      }
    }

    Widget main = ListView(
      controller: _controller,
      children: mainList,
    );

    if (TableModeUtil.isTableMode()) {
      main = GestureDetector(
        onVerticalDragUpdate: (detail) {
          _controller.jumpTo(_controller.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: appBarTitle,
      ),
      body: EventReplyCallback(
        onReplyCallback: onReplyCallback,
        child: main,
      ),
    );
  }

  void fetchDatas() {
    box.clear();
    parentEventTraces.clear();
    rootSubList.clear();
    forceParentId = null;
    sourceEventKey = GlobalKey();

    wotProvider.addTempFromEvent(sourceEvent!);

    // find parent data
    var eventRelation = EventRelation.fromEvent(sourceEvent!);
    var replyId = eventRelation.replyOrRootId;
    if (StringUtil.isNotBlank(replyId)) {
      // this query move onReplyQueryComplete function call, avoid query limit.
      // findParentEvent(replyId!);

      // this sourceEvent has parent event, so it is reply event, only show the sub reply events.
      forceParentId = sourceEvent!.id;
    }

    // find reply data
    AId? aId;
    if (eventRelation.aId != null &&
        eventRelation.aId!.kind == EventKind.LONG_FORM) {
      aId = eventRelation.aId;
    }

    List<int> replyKinds = [...EventKindType.SUPPORTED_EVENTS]
      ..remove(EventKind.REPOST)
      ..remove(EventKind.LONG_FORM)
      ..add(EventKind.ZAP);

    // query sub events
    var parentIds = [sourceEvent!.id];
    if (StringUtil.isNotBlank(eventRelation.rootId)) {
      // only the query from root can query all sub replies.
      parentIds.add(eventRelation.rootId!);
      // parentIds = [eventRelation.rootId!];
    }
    var filter = Filter(e: parentIds, kinds: replyKinds);

    var filters = [filter.toJson()];
    if (aId != null) {
      var f = Filter(kinds: replyKinds);
      var m = f.toJson();
      m["#a"] = [aId.toAString()];
      filters.add(m);
    }

    List<String> tempRelays = [];
    if (StringUtil.isNotBlank(eventRelation.replyOrRootRelayAddr)) {
      var eventRelays = nostr!
          .getExtralReadableRelays([eventRelation.replyOrRootRelayAddr!], 1);
      tempRelays.addAll(eventRelays);
    }
    if (StringUtil.isNotBlank(eventRelation.pubkey)) {
      var subEventPubkeyRelays =
          metadataProvider.getExtralRelays(eventRelation.pubkey, false);
      tempRelays.addAll(subEventPubkeyRelays);
    }

    beginQueryParentFlag = false;
    nostr!.query(filters, onEvent,
        onComplete: beginQueryParent,
        targetRelays: tempRelays,
        relayTypes: RelayType.NORMAL_AND_CACHE,
        bothRelay: true);
    Future.delayed(const Duration(seconds: 1)).then((value) {
      // avoid query onComplete no callback.
      beginQueryParent();
    });
  }

  var beginQueryParentFlag = false;

  void beginQueryParent() {
    if (!beginQueryParentFlag) {
      beginQueryParentFlag = true;
      var eventRelation = EventRelation.fromEvent(sourceEvent!);
      var replyId = eventRelation.replyOrRootId;
      if (StringUtil.isNotBlank(replyId)) {
        findParentEvent(replyId!,
            eventRelayAddr: eventRelation.replyOrRootRelayAddr,
            subEventPubkey: sourceEvent!.pubkey);
      }
    }
  }

  String parentEventId(String eventId) {
    return "eventTrace${eventId.substring(0, 8)}";
  }

  void findParentEvent(String eventId,
      {String? eventRelayAddr, String? subEventPubkey}) {
    // log("findParentEvent $eventId");
    // query from reply events
    var pe = box.getById(eventId);
    if (pe != null) {
      onParentEvent(pe);
      return;
    }

    // query from singleEventProvider
    pe = singleEventProvider.getEvent(eventId, queryData: false);
    if (pe != null) {
      onParentEvent(pe);
      return;
    }

    var filter = Filter(ids: [eventId]);
    List<String> tempRelays = [];
    if (StringUtil.isNotBlank(eventRelayAddr)) {
      var eventRelays = nostr!.getExtralReadableRelays([eventRelayAddr!], 1);
      tempRelays.addAll(eventRelays);
    }
    if (StringUtil.isNotBlank(subEventPubkey)) {
      var subEventPubkeyRelays =
          metadataProvider.getExtralRelays(subEventPubkey!, false);
      tempRelays.addAll(subEventPubkeyRelays);
    }
    nostr!.query([filter.toJson()], onParentEvent,
        id: parentEventId(eventId),
        targetRelays: tempRelays,
        relayTypes: RelayType.NORMAL_AND_CACHE,
        bothRelay: true);
  }

  void onParentEvent(Event e) {
    // log(jsonEncode(e.toJson()));
    singleEventProvider.onEvent(e);

    EventTraceInfo? addedEti;
    if (parentEventTraces.isEmpty) {
      addedEti = EventTraceInfo(e);
      parentEventTraces.add(addedEti);
    } else {
      if (parentEventTraces.last.eventRelation.replyOrRootId == e.id) {
        addedEti = EventTraceInfo(e);
        parentEventTraces.add(addedEti);
      }
    }

    if (addedEti != null) {
      // a new event find, try to find a new parent event
      var replyId = addedEti.eventRelation.replyOrRootId;
      if (StringUtil.isNotBlank(replyId)) {
        findParentEvent(replyId!,
            eventRelayAddr: addedEti.eventRelation.replyOrRootRelayAddr,
            subEventPubkey: addedEti.event.pubkey);
      }

      setState(() {});
      scrollToSourceEvent();
    }
  }
}
