import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip19/nip19_tlv.dart';
import 'package:nostr_sdk/nip51/follow_set.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostr_sdk/utils/when_stop_function.dart';
import 'package:nostrmo/component/appbar4stack.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/router/index/index_app_bar.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/event/event_list_component.dart';
import '../../component/placeholder/event_list_placeholder.dart';
import '../../consts/base_consts.dart';
import '../../consts/event_kind_type.dart';
import '../../generated/l10n.dart';
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

  late S s;

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
    // _controller.addListener(() {
    //   if (_controller.offset > 50 && mainColor != null) {
    //     appBarBG = mainColor!.withOpacity(0.2);
    //     setState(() {});
    //   } else {
    //     appBarBG = null;
    //     setState(() {});
    //   }
    // });
  }

  @override
  Widget doBuild(BuildContext context) {
    s = S.of(context);

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
    var appBarTextColor = themeData.appBarTheme.titleTextStyle!.color;
    var mediumFontSize = themeData.textTheme.bodyMedium!.fontSize;
    var popFontStyle = TextStyle(
      fontSize: mediumFontSize,
    );

    late Widget main;

    var events = box.all();
    if (events.isEmpty) {
      main = EventListPlaceholder(
        onRefresh: () {
          box.clear;
          doQuery();
        },
      );
    } else {
      main = ListView.builder(
        controller: _controller,
        itemBuilder: (BuildContext context, int index) {
          var event = events[index];
          return EventListComponent(
            event: event,
            showVideo: _settingProvider.videoPreviewInList != OpenStatus.CLOSE,
          );
        },
        itemCount: events.length,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          followSet!.displayName(),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: themeData.textTheme.bodyLarge!.fontSize),
        ),
        actions: [
          PopupMenuButton(
            onSelected: onPopMenuSelected,
            tooltip: s.More,
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: "copyNaddr",
                  child: Row(
                    children: [
                      Icon(Icons.copy),
                      Text(" ${s.Copy} ${s.Address}")
                    ],
                  ),
                ),
              ];
            },
            child: Container(
              padding: const EdgeInsets.only(
                left: Base.BASE_PADDING_HALF,
                right: Base.BASE_PADDING_HALF,
              ),
              child: const Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
      body: main,
    );
  }

  void onPopMenuSelected(value) {
    if (value == "copyNaddr") {
      var naddr = followSet!.getNaddr();
      print(naddr.toString());
      Clipboard.setData(ClipboardData(text: NIP19Tlv.encodeNaddr(naddr)));
      BotToast.showText(text: S.of(context).Copy_success);
    }
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
