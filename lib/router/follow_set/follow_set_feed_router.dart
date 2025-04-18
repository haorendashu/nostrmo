import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip51/follow_set.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostr_sdk/utils/when_stop_function.dart';
import 'package:nostrmo/component/appbar4stack.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/router/index/index_app_bar.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/event/event_list_component.dart';
import '../../component/placeholder/event_list_placeholder.dart';
import '../../consts/base_consts.dart';
import '../../consts/event_kind_type.dart';
import '../../main.dart';
import '../../provider/setting_provider.dart';
import '../../util/load_more_event.dart';
import 'package:nostr_sdk/utils/string_util.dart';

class FollowSetFeedRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FollowSetFeedRouter();
  }
}

class _FollowSetFeedRouter extends CustState<FollowSetFeedRouter>
    with PenddingEventsLaterFunction, LoadMoreEvent, WhenStopFunction {
  EventMemBox box = EventMemBox();

  ScrollController _controller = ScrollController();

  FollowSet? followSet;

  Color? mainColor;

  Color? appBarBG;

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
    _controller.addListener(() {
      if (_controller.offset > 50 && mainColor != null) {
        appBarBG = mainColor!.withOpacity(0.2);
        setState(() {});
      } else {
        appBarBG = null;
        setState(() {});
      }
    });
  }

  @override
  Widget doBuild(BuildContext context) {
    if (followSet == null) {
      var followSetItf = RouterUtil.routerArgs(context);
      if (followSetItf == null) {
        RouterUtil.back(context);
        return Container();
      }

      followSet = followSetItf as FollowSet?;
    } else {
      var followSetItf = RouterUtil.routerArgs(context);
      if (followSetItf != null && followSetItf is FollowSet) {
        if (followSet!.dTag != followSetItf.dTag) {
          box = EventMemBox();

          doQuery();
        }
      }
    }

    var themeData = Theme.of(context);
    var _settingProvider = Provider.of<SettingProvider>(context);
    var mediaQuery = MediaQuery.of(context);
    var padding = mediaQuery.padding;
    mainColor = themeData.primaryColor;
    var appBarTextColor = themeData.appBarTheme.titleTextStyle!.color;

    var events = box.all();
    if (events.isEmpty) {
      return Scaffold(
        appBar: AppBar(leading: AppbarBackBtnComponent()),
        body: EventListPlaceholder(
          onRefresh: () {
            box.clear;
            doQuery();
          },
        ),
      );
    }

    var currentAppBarBG = mainColor;
    if (appBarBG != null) {
      currentAppBarBG = appBarBG;
    }

    var main = ListView.builder(
      controller: _controller,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Container(
            height: Appbar4Stack.height,
          );
        }

        var event = events[index];
        return EventListComponent(
          event: event,
          showVideo: _settingProvider.videoPreviewInList != OpenStatus.CLOSE,
        );
      },
      itemCount: events.length + 1,
    );

    return Scaffold(
      body: Stack(
        children: [
          main,
          Positioned.fill(
            top: 0,
            bottom: mediaQuery.size.height - padding.top - Appbar4Stack.height,
            child: Container(
              color: currentAppBarBG,
              padding: EdgeInsets.only(top: padding.top),
              child: Appbar4Stack(
                title: Text(
                  followSet!.displayName(),
                  style: TextStyle(
                    color: appBarTextColor,
                    fontSize: themeData.textTheme.bodyLarge!.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.transparent,
                textColor: appBarTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? subscribeId;

  @override
  Future<void> onReady(BuildContext context) async {
    doQuery();
  }

  @override
  void doQuery() {
    _doQuery(onEventFunc: onEvent);
  }

  void _doQuery({Function(Event)? onEventFunc}) {
    var contacts = followSet!.list();
    if (contacts.isEmpty) {
      return;
    }

    // print("_doQuery");
    onEventFunc ??= onEvent;

    preQuery();
    if (StringUtil.isNotBlank(subscribeId)) {
      unSubscribe();
    }

    // load event from relay
    var filter = Filter(
      kinds: EventKindType.SUPPORTED_EVENTS,
      until: until,
      limit: queryLimit,
    );
    subscribeId = StringUtil.rndNameStr(16);
    List<String> ids = [];
    for (var contact in contacts) {
      ids.add(contact.publicKey);
      // ignore ids length very big issue
    }
    filter.authors = ids;

    if (!box.isEmpty() && readyComplete) {
      // query after init
      var activeRelays = nostr!.activeRelays();
      var oldestCreatedAts = box.oldestCreatedAtByRelay(activeRelays);
      Map<String, List<Map<String, dynamic>>> filtersMap = {};
      for (var relay in activeRelays) {
        var oldestCreatedAt = oldestCreatedAts.createdAtMap[relay.url];
        if (oldestCreatedAt != null) {
          filter.until = oldestCreatedAt;
          if (!forceUserLimit) {
            filter.limit = null;
            if (filter.until! < oldestCreatedAts.avCreatedAt - 60 * 60 * 18) {
              filter.since = oldestCreatedAt - 60 * 60 * 12;
            } else if (filter.until! >
                oldestCreatedAts.avCreatedAt - 60 * 60 * 6) {
              filter.since = oldestCreatedAt - 60 * 60 * 36;
            } else {
              filter.since = oldestCreatedAt - 60 * 60 * 24;
            }
          }
          filtersMap[relay.url] = [filter.toJson()];
        }
      }
      nostr!.queryByFilters(filtersMap, onEvent, id: subscribeId);
    } else {
      // this is init query
      // try to query from user's write relay.
      nostr!.query([filter.toJson()], onEvent, id: subscribeId);
    }

    readyComplete = true;
  }

  void onEvent(event) {
    later(event, (list) {
      box.addList(list);
      setState(() {});
    }, null);
  }

  @override
  EventMemBox getEventBox() {
    return box;
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();

    if (StringUtil.isNotBlank(subscribeId)) {
      try {
        nostr!.unsubscribe(subscribeId!);
      } catch (e) {}
    }
  }

  void unSubscribe() {
    nostr!.unsubscribe(subscribeId!);
    subscribeId = null;
  }
}
