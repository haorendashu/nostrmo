import 'package:flutter/material.dart';
import 'package:nostrmo/component/community_info_component.dart';
import 'package:provider/provider.dart';
import 'package:widget_size/widget_size.dart';

import '../../client/event.dart';
import '../../client/filter.dart';
import '../../client/nip172/community_id.dart';
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

class CommunityDetailRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CommunityDetailRouter();
  }
}

class _CommunityDetailRouter extends CustState<CommunityDetailRouter>
    with PenddingEventsLaterFunction {
  EventMemBox box = EventMemBox();

  CommunityId? communityId;

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
    if (communityId == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        communityId = arg as CommunityId;
      }
    }
    if (communityId == null) {
      RouterUtil.back(context);
      return Container();
    }
    var _settingProvider = Provider.of<SettingProvider>(context);
    var themeData = Theme.of(context);
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    Widget? appBarTitle;
    if (showTitle) {
      appBarTitle = Text(
        communityId!.title,
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
            if (communityInfo != null) {
              return WidgetSize(
                onChange: (s) {
                  infoHeight = s.height;
                },
                child: CommunityInfoComponent(info: communityInfo!),
              );
            } else {
              return Container();
            }
          }

          var event = box.get(index - 1);
          if (event == null) {
            return null;
          }

          return EventListComponent(
            event: event,
            showVideo: _settingProvider.videoPreviewInList == OpenStatus.OPEN,
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
        actions: [],
        title: appBarTitle,
      ),
      body: main,
    );
  }

  var infoSubscribeId = StringUtil.rndNameStr(16);

  var subscribeId = StringUtil.rndNameStr(16);

  CommunityInfo? communityInfo;

  @override
  Future<void> onReady(BuildContext context) async {
    if (communityId != null) {
      {
        var filter = Filter(kinds: [
          kind.EventKind.COMMUNITY_DEFINITION,
        ], authors: [
          communityId!.pubkey
        ], limit: 1);
        var queryArg = filter.toJson();
        queryArg["#d"] = [communityId!.title];
        nostr!.query([queryArg], (e) {
          if (communityInfo == null || communityInfo!.createdAt < e.createdAt) {
            var ci = CommunityInfo.fromEvent(e);
            if (ci != null) {
              setState(() {
                communityInfo = ci;
              });
            }
          }
        }, id: infoSubscribeId);
      }
      {
        var filter = Filter(kinds: [
          kind.EventKind.TEXT_NOTE,
          kind.EventKind.LONG_FORM,
          kind.EventKind.FILE_HEADER,
          kind.EventKind.POLL,
        ], limit: 100);
        var queryArg = filter.toJson();
        queryArg["#a"] = [communityId!.toAString()];
        nostr!.query([queryArg], onEvent, id: subscribeId);
      }
    }
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
}
