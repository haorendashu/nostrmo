import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/component/simple_name_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:provider/provider.dart';

import '../../client/event.dart';
import '../../client/event_kind.dart' as kind;
import '../../client/filter.dart';
import '../../component/appbar4stack.dart';
import '../../component/cust_state.dart';
import '../../component/event/event_list_component.dart';
import '../../component/user/metadata_component.dart';
import '../../consts/base_consts.dart';
import '../../data/event_mem_box.dart';
import '../../data/metadata.dart';
import '../../main.dart';
import '../../provider/metadata_provider.dart';
import '../../provider/setting_provider.dart';
import '../../util/load_more_event.dart';
import '../../util/peddingevents_later_function.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';
import '../../util/when_stop_function.dart';
import 'user_statistics_component.dart';

class UserRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _UserRouter();
  }
}

class _UserRouter extends CustState<UserRouter>
    with PenddingEventsLaterFunction, LoadMoreEvent, WhenStopFunction {
  final GlobalKey<NestedScrollViewState> globalKey = GlobalKey();

  ScrollController _controller = ScrollController();

  String? pubkey;

  bool showTitle = false;

  bool showAppbarBG = false;

  EventMemBox box = EventMemBox();

  @override
  void initState() {
    super.initState();

    whenStopMS = 1500;
    queryLimit = 200;

    _controller.addListener(() {
      var _showTitle = false;
      var _showAppbarBG = false;

      var offset = _controller.offset;
      if (offset > showTitleHeight) {
        _showTitle = true;
      }
      if (offset > showAppbarBGHeight) {
        _showAppbarBG = true;
      }

      if (_showTitle != showTitle || _showAppbarBG != showAppbarBG) {
        setState(() {
          showTitle = _showTitle;
          showAppbarBG = _showAppbarBG;
        });
      }
    });
  }

  /// the offset to show title, bannerHeight + 50;
  double showTitleHeight = 50;

  /// the offset to appbar background color, showTitleHeight + 100;
  double showAppbarBGHeight = 50 + 100;

  @override
  Widget doBuild(BuildContext context) {
    var _settingProvider = Provider.of<SettingProvider>(context);
    if (StringUtil.isBlank(pubkey)) {
      pubkey = RouterUtil.routerArgs(context) as String?;
      if (StringUtil.isBlank(pubkey)) {
        RouterUtil.back(context);
        return Container();
      }
      var events = followEventProvider.eventsByPubkey(pubkey!);
      if (events != null && events.isNotEmpty) {
        box.addList(events);
      }
    } else {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is String) {
        if (arg != pubkey) {
          // arg change! reset.
          box.clear();
          until = null;

          pubkey = arg;
          doQuery();
        }
      }
    }
    preBuild();

    var paddingTop = mediaDataCache.padding.top;
    var maxWidth = mediaDataCache.size.width;

    showTitleHeight = maxWidth / 3 + 50;
    showAppbarBGHeight = showTitleHeight + 100;

    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    return Selector<MetadataProvider, Metadata?>(
      shouldRebuild: (previous, next) {
        return previous != next;
      },
      selector: (context, _metadataProvider) {
        return _metadataProvider.getMetadata(pubkey!);
      },
      builder: (context, metadata, child) {
        Color? appbarBackgroundColor = Colors.transparent;
        if (showAppbarBG) {
          appbarBackgroundColor = Colors.white.withOpacity(0.6);
        }
        Widget? appbarTitle;
        if (showTitle) {
          String displayName =
              SimpleNameComponent.getSimpleName(pubkey!, metadata);

          appbarTitle = Container(
            alignment: Alignment.center,
            child: Text(
              displayName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: themeData.textTheme.bodyLarge!.fontSize,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
        var appBar = Appbar4Stack(
          backgroundColor: appbarBackgroundColor,
          title: appbarTitle,
        );

        Widget main = NestedScrollView(
          key: globalKey,
          controller: _controller,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverToBoxAdapter(
                child: MetadataComponent(
                  pubKey: pubkey!,
                  metadata: metadata,
                  showBadges: true,
                  userPicturePreview: true,
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: UserStatisticsComponent(
                    pubkey: pubkey!,
                  ),
                ),
              ),
            ];
          },
          body: MediaQuery.removePadding(
            removeTop: true,
            context: context,
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                var event = box.get(index);
                if (event == null) {
                  return null;
                }
                return EventListComponent(
                  event: event,
                  showVideo:
                      _settingProvider.videoPreviewInList == OpenStatus.OPEN,
                );
              },
              itemCount: box.length(),
            ),
          ),
        );

        List<Widget> mainList = [
          main,
          Positioned(
            top: paddingTop,
            child: Container(
              width: maxWidth,
              child: appBar,
            ),
          ),
        ];

        if (dataSyncMode) {
          mainList.add(Positioned(
            right: Base.BASE_PADDING * 2,
            bottom: Base.BASE_PADDING * 4,
            child: GestureDetector(
              onTap: beginToSyncAll,
              child: const Icon(Icons.cloud_sync),
            ),
          ));
        }

        return Scaffold(
            body: Stack(
          children: mainList,
        ));
      },
    );
  }

  String? subscribeId;

  @override
  Future<void> onReady(BuildContext context) async {
    doQuery();

    if (globalKey.currentState != null) {
      var controller = globalKey.currentState!.innerController;
      controller.addListener(() {
        loadMoreScrollCallback(controller);
      });
    }

    metadataProvider.update(pubkey!);
  }

  void onEvent(event) {
    later(event, (list) {
      box.addList(list);
      setState(() {});
    }, null);
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

    closeLoading();
  }

  void unSubscribe() {
    nostr!.unsubscribe(subscribeId!);
    subscribeId = null;
  }

  @override
  void doQuery() {
    _doQuery(onEventFunc: onEvent);
  }

  void _doQuery({Function(Event)? onEventFunc}) {
    // print("_doQuery");
    onEventFunc ??= onEvent;

    preQuery();
    if (StringUtil.isNotBlank(subscribeId)) {
      unSubscribe();
    }

    // load event from relay
    var filter = Filter(
      kinds: kind.EventKind.SUPPORTED_EVENTS,
      until: until,
      authors: [pubkey!],
      limit: queryLimit,
    );
    subscribeId = StringUtil.rndNameStr(16);

    if (!box.isEmpty() && readyComplete) {
      // query after init
      var activeRelays = nostr!.activeRelays();
      var oldestCreatedAts = box.oldestCreatedAtByRelay(
        activeRelays,
      );
      Map<String, List<Map<String, dynamic>>> filtersMap = {};
      for (var relay in activeRelays) {
        var oldestCreatedAt = oldestCreatedAts.createdAtMap[relay.url];
        filter.until = oldestCreatedAt;
        filtersMap[relay.url] = [filter.toJson()];
      }
      nostr!.queryByFilters(filtersMap, onEventFunc, id: subscribeId);
    } else {
      // this is init query
      // try to query from user's write relay.
      List<String>? tempRelays =
          metadataProvider.getExtralRelays(pubkey!, true);
      nostr!.query([filter.toJson()], onEventFunc,
          id: subscribeId, tempRelays: tempRelays, onlyTempRelays: false);
    }

    readyComplete = true;
  }

  var oldEventLength = 0;

  void syncAllOnEvent(Event e) {
    onEvent(e);
    whenStop(() {
      log("whenStop box length ${box.length()}");
      if (box.length() > oldEventLength) {
        oldEventLength = box.length();
        _doQuery(onEventFunc: syncAllOnEvent);
      } else {
        unSubscribe();
        // sync download complete
        broadcaseAll();
      }
    });
  }

  Future<void> broadcaseAll() async {
    var activeRelays = nostr!.activeRelays();

    log("begin to broadcaseAll");
    var list = box.all();
    // var index = 0;
    for (var event in list) {
      var message = ["EVENT", event.toJson()];

      // find the relays not contain this event and send (broadcase) to it.
      // int count = 0;
      for (var relay in activeRelays) {
        if (!event.sources.contains(relay.url)) {
          try {
            // count++;
            relay.send(message);
          } catch (e) {}
        }
      }
      // log("note ${index} send to ${count} relays");

      // nostr!.broadcase(event);
      await Future.delayed(const Duration(milliseconds: 10));
      // index++;
    }
    log("broadcaseAll complete");
    closeLoading();
  }

  @override
  EventMemBox getEventBox() {
    return box;
  }

  CancelFunc? cancelFunc;

  void beginToSyncAll() {
    cancelFunc = BotToast.showLoading();
    oldEventLength = box.length();
    _doQuery(onEventFunc: syncAllOnEvent);
  }

  void closeLoading() {
    if (cancelFunc != null) {
      try {
        cancelFunc!.call();
        cancelFunc = null;
      } catch (e) {}
    }
  }
}
