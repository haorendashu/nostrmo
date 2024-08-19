import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/event_relation.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostrmo/provider/replaceable_event_provider.dart';
import 'package:nostrmo/provider/single_event_provider.dart';
import 'package:provider/provider.dart';
import 'package:widget_size/widget_size.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/cust_state.dart';
import '../../component/event/event_list_component.dart';
import '../../component/event/event_load_list_component.dart';
import '../../component/event_reply_callback.dart';
import '../../component/user/simple_name_component.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/peddingevents_later_function.dart';
import '../../util/router_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import '../../util/table_mode_util.dart';
import '../../util/when_stop_function.dart';
import 'thread_detail_event.dart';
import 'thread_detail_event_main_component.dart';
import 'thread_detail_item_component.dart';
import 'thread_router_helper.dart';

class ThreadDetailRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ThreadDetailRouter();
  }

  static String getAppBarTitle(Event event) {
    return event.content.replaceAll("\n", " ").replaceAll("\r", " ");
  }

  static Widget detailAppBarTitle(
      String pubkey, String title, ThemeData themeData) {
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> appBarTitleList = [];
    var nameComponnet = SimpleNameComponent(
      pubkey: pubkey,
      textStyle: TextStyle(
        fontSize: bodyLargeFontSize,
        color: themeData.appBarTheme.titleTextStyle!.color,
      ),
    );
    appBarTitleList.add(nameComponnet);
    appBarTitleList.add(Text(" : "));
    appBarTitleList.add(Expanded(
        child: Text(
      title,
      style: TextStyle(
        overflow: TextOverflow.ellipsis,
        fontSize: bodyLargeFontSize,
      ),
    )));
    return Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: appBarTitleList,
      ),
    );
  }
}

class _ThreadDetailRouter extends CustState<ThreadDetailRouter>
    with PenddingEventsLaterFunction, WhenStopFunction, ThreadRouterHelper {
  Event? sourceEvent;

  bool showTitle = false;

  ScrollController _controller = ScrollController();

  double rootEventHeight = 120;

  String? titlePubkey;

  String? title;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.offset > rootEventHeight * 0.5 && !showTitle) {
        setState(() {
          showTitle = true;
        });
      } else if (_controller.offset < rootEventHeight * 0.5 && showTitle) {
        setState(() {
          showTitle = false;
        });
      }
    });
  }

  void initFromArgs() {
    // do some init oper
    var eventRelation = EventRelation.fromEvent(sourceEvent!);
    rootId = eventRelation.rootId;
    rootEventRelayAddr = eventRelation.rootRelayAddr;
    if (eventRelation.aId != null &&
        eventRelation.aId!.kind == EventKind.LONG_FORM) {
      aId = eventRelation.aId;
    }
    if (rootId == null) {
      if (aId == null) {
        if (eventRelation.replyId != null) {
          rootId = eventRelation.replyId;
        } else {
          // source event is root event
          rootId = sourceEvent!.id;
          rootEvent = sourceEvent!;
        }
      } else {
        // aid linked root event
        rootEvent = replaceableEventProvider.getEvent(aId!);
        if (rootEvent != null) {
          rootId = rootEvent!.id;
        }
      }
    }
    if (rootEvent != null && StringUtil.isNotBlank(eventRelation.dTag)) {
      aId = AId(
          kind: rootEvent!.kind,
          pubkey: rootEvent!.pubkey,
          title: eventRelation.dTag!);
    }

    // load replies from cache and avoid blank page
    {
      var eventReactions =
          eventReactionsProvider.get(sourceEvent!.id, avoidPull: true);
      if (eventReactions != null && eventReactions.replies.isNotEmpty) {
        box.addList(eventReactions.replies);
      }
    }
    if (rootId != null && rootId != sourceEvent!.id) {
      var eventReactions = eventReactionsProvider.get(rootId!, avoidPull: true);
      if (eventReactions != null && eventReactions.replies.isNotEmpty) {
        box.addList(eventReactions.replies);
      }
    }
    if (rootEvent == null) {
      box.add(sourceEvent!);
    }
    listToTree(refresh: false);
  }

  @override
  Widget doBuild(BuildContext context) {
    var s = S.of(context);
    if (sourceEvent == null) {
      var obj = RouterUtil.routerArgs(context);
      if (obj != null && obj is Event) {
        sourceEvent = obj;
      }
      if (sourceEvent == null) {
        RouterUtil.back(context);
        return Container();
      }

      initFromArgs();
    } else {
      var obj = RouterUtil.routerArgs(context);
      if (obj != null && obj is Event) {
        if (obj.id != sourceEvent!.id) {
          // arg change! reset.
          sourceEvent = null;
          rootId = null;
          rootEvent = null;
          box = EventMemBox();
          rootSubList = [];

          sourceEvent = obj;
          initFromArgs();
          doQuery();
        }
      }
    }

    var themeData = Theme.of(context);
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    var cardColor = themeData.cardColor;

    Widget? appBarTitle;
    if (rootEvent != null) {
      titlePubkey = rootEvent!.pubkey;
      title = ThreadDetailRouter.getAppBarTitle(rootEvent!);
    }
    if (showTitle) {
      if (StringUtil.isNotBlank(titlePubkey) && StringUtil.isNotBlank(title)) {
        appBarTitle = ThreadDetailRouter.detailAppBarTitle(
            titlePubkey!, title!, themeData);
      }
    }

    Widget? rootEventWidget;
    if (rootEvent == null) {
      if (StringUtil.isNotBlank(rootId)) {
        rootEventWidget = Selector<SingleEventProvider, Event?>(
            builder: (context, event, child) {
          if (event == null) {
            return EventLoadListComponent();
          }

          titlePubkey = event.pubkey;
          title = ThreadDetailRouter.getAppBarTitle(event);

          {
            // check if the rootEvent isn't rootEvent
            var newRelation = EventRelation.fromEvent(event);
            String? newRootId;
            String? newRootEventRelayAddr;
            if (newRelation.rootId != null) {
              newRootId = newRelation.rootId;
              newRootEventRelayAddr = newRelation.rootRelayAddr;
            } else if (newRelation.replyId != null) {
              newRootId = newRelation.replyId;
              newRootEventRelayAddr = newRelation.replyRelayAddr;
            }

            if (StringUtil.isNotBlank(newRootId)) {
              rootId = newRootId;
              rootEventRelayAddr = newRootEventRelayAddr;
              doQuery();
              singleEventProvider.getEvent(newRootId!,
                  eventRelayAddr: newRootEventRelayAddr);
            }
          }

          return EventListComponent(
            event: event,
            jumpable: false,
            showVideo: true,
            imageListMode: false,
            showLongContent: true,
          );
        }, selector: (context, provider) {
          return provider.getEvent(rootId!, eventRelayAddr: rootEventRelayAddr);
        });
      } else if (aId != null) {
        rootEventWidget = Selector<ReplaceableEventProvider, Event?>(
            builder: (context, event, child) {
          if (event == null) {
            return EventLoadListComponent();
          }

          if (rootId != null) {
            // find the root event now! try to load data again!
            rootId = event.id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              doQuery();
            });
          }

          titlePubkey = event.pubkey;
          title = ThreadDetailRouter.getAppBarTitle(event);

          return EventListComponent(
            event: event,
            jumpable: false,
            showVideo: true,
            imageListMode: false,
            showLongContent: true,
          );
        }, selector: (context, provider) {
          return provider.getEvent(aId!);
        });
      } else {
        rootEventWidget = Container();
      }
    } else {
      rootEventWidget = EventListComponent(
        event: rootEvent!,
        jumpable: false,
        showVideo: true,
        imageListMode: false,
        showLongContent: true,
      );
    }

    List<Widget> mainList = [];

    mainList.add(WidgetSize(
      child: rootEventWidget,
      onChange: (size) {
        rootEventHeight = size.height;
      },
    ));

    for (var item in rootSubList!) {
      // if (item.event.kind == kind.EventKind.ZAP &&
      //     StringUtil.isBlank(item.event.content)) {
      //   continue;
      // }

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

  @override
  Future<void> onReady(BuildContext context) async {
    doQuery();
  }

  void doQuery() {
    if (StringUtil.isNotBlank(rootId)) {
      // if (rootEvent == null) {
      //   // source event isn't root event，query root event
      //   var filter = Filter(ids: [rootId!]);
      //   nostr!.query([filter.toJson()], onRootEvent);
      // }

      List<int> replyKinds = [...EventKind.SUPPORTED_EVENTS]
        ..remove(EventKind.REPOST)
        ..remove(EventKind.LONG_FORM)
        ..add(EventKind.ZAP);

      // query sub events
      var filter = Filter(e: [rootId!], kinds: replyKinds);

      var filters = [filter.toJson()];
      if (aId != null) {
        var f = Filter(kinds: replyKinds);
        var m = f.toJson();
        m["#a"] = [aId!.toAString()];
        filters.add(m);
      }

      // print(filters);

      nostr!.query(filters, onEvent);
    }
  }

  AId? aId;

  String? rootId;

  String? rootEventRelayAddr;

  Event? rootEvent;
}
