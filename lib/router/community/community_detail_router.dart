import 'package:flutter/material.dart';
import 'package:nostrmo/client/aid.dart';
import 'package:nostrmo/component/community_info_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/provider/community_info_provider.dart';
import 'package:provider/provider.dart';
import 'package:widget_size/widget_size.dart';

import '../../client/event.dart';
import '../../client/filter.dart';
import '../../client/nip172/community_info.dart';
import '../../component/cust_state.dart';
import '../../component/event/event_list_component.dart';
import '../../component/event_delete_callback.dart';
import '../../consts/base_consts.dart';
import '../../data/event_mem_box.dart';
import '../../main.dart';
import '../../provider/setting_provider.dart';
import '../../util/peddingevents_later_function.dart';
import '../../util/router_util.dart';
import '../../client/event_kind.dart' as kind;
import '../../util/string_util.dart';
import '../edit/editor_router.dart';

class CommunityDetailRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CommunityDetailRouter();
  }
}

class _CommunityDetailRouter extends CustState<CommunityDetailRouter>
    with PenddingEventsLaterFunction {
  EventMemBox box = EventMemBox();

  AId? aId;

  ScrollController _controller = ScrollController();

  bool showTitle = false;

  double infoHeight = 80;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.offset > infoHeight * 0.8 && !showTitle) {
        setState(() {
          showTitle = true;
        });
      } else if (_controller.offset < infoHeight * 0.8 && showTitle) {
        setState(() {
          showTitle = false;
        });
      }
    });
  }

  @override
  Widget doBuild(BuildContext context) {
    if (aId == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        aId = arg as AId;
      }
    }
    if (aId == null) {
      RouterUtil.back(context);
      return Container();
    }
    var _settingProvider = Provider.of<SettingProvider>(context);
    var themeData = Theme.of(context);
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    Widget? appBarTitle;
    if (showTitle) {
      appBarTitle = Text(
        aId!.title,
        style: TextStyle(
          fontSize: bodyLargeFontSize,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    Widget main = EventDeleteCallback(
      onDeleteCallback: onDeleteCallback,
      child: ListView.builder(
        controller: _controller,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Selector<CommunityInfoProvider, CommunityInfo?>(
                builder: (context, info, child) {
              if (info == null) {
                return Container();
              }

              return WidgetSize(
                onChange: (s) {
                  infoHeight = s.height;
                },
                child: CommunityInfoComponent(info: info!),
              );
            }, selector: (context, _provider) {
              return _provider.getCommunity(aId!.toAString());
            });
          }

          var event = box.get(index - 1);
          if (event == null) {
            return null;
          }

          return EventListComponent(
            event: event,
            showVideo: _settingProvider.videoPreviewInList != OpenStatus.CLOSE,
            showCommunity: false,
          );
        },
        itemCount: box.length() + 1,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: themeData.appBarTheme.titleTextStyle!.color,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: addToCommunity,
            child: Container(
              margin: const EdgeInsets.only(
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
              ),
              child: Icon(
                Icons.add,
                color: themeData.appBarTheme.titleTextStyle!.color,
              ),
            ),
          )
        ],
        title: appBarTitle,
      ),
      body: main,
    );
  }

  var infoSubscribeId = StringUtil.rndNameStr(16);

  var subscribeId = StringUtil.rndNameStr(16);

  // CommunityInfo? communityInfo;

  @override
  Future<void> onReady(BuildContext context) async {
    if (aId != null) {
      // {
      //   var filter = Filter(kinds: [
      //     kind.EventKind.COMMUNITY_DEFINITION,
      //   ], authors: [
      //     aId!.pubkey
      //   ], limit: 1);
      //   var queryArg = filter.toJson();
      //   queryArg["#d"] = [aId!.title];
      //   nostr!.query([queryArg], (e) {
      //     if (communityInfo == null || communityInfo!.createdAt < e.createdAt) {
      //       var ci = CommunityInfo.fromEvent(e);
      //       if (ci != null) {
      //         setState(() {
      //           communityInfo = ci;
      //         });
      //       }
      //     }
      //   }, id: infoSubscribeId);
      // }
      queryEvents();
    }
  }

  void queryEvents() {
    var filter = Filter(kinds: kind.EventKind.SUPPORTED_EVENTS, limit: 100);
    var queryArg = filter.toJson();
    queryArg["#a"] = [aId!.toAString()];
    nostr!.query([queryArg], onEvent, id: subscribeId);
  }

  void onEvent(Event event) {
    later(event, (list) {
      box.addList(list);
      setState(() {});
    }, null);
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();

    try {
      nostr!.unsubscribe(subscribeId);
    } catch (e) {}
  }

  onDeleteCallback(Event event) {
    box.delete(event.id);
    setState(() {});
  }

  Future<void> addToCommunity() async {
    if (aId != null) {
      List<String> aTag = ["a", aId!.toAString()];
      if (relayProvider.relayAddrs.isNotEmpty) {
        aTag.add(relayProvider.relayAddrs[0]);
      }

      var event = await EditorRouter.open(context, tags: [aTag]);
      if (event != null) {
        queryEvents();
      }
    }
  }
}
