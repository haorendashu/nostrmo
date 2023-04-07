import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/event_relation.dart';
import 'package:nostrmo/component/event/event_list_component.dart';
import 'package:nostrmo/component/event_reply_callback.dart';
import 'package:nostrmo/component/name_component.dart';
import 'package:nostrmo/component/simple_name_component.dart';
import 'package:nostrmo/router/thread/thread_detail_event.dart';
import 'package:nostrmo/router/thread/thread_detail_item_component.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';
import 'package:widget_size/widget_size.dart';

import '../../client/filter.dart';
import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../data/event_mem_box.dart';
import '../../data/metadata.dart';
import '../../main.dart';
import '../../provider/metadata_provider.dart';
import '../../util/peddingevents_later_function.dart';
import '../../util/router_util.dart';
import '../../client/event_kind.dart' as kind;

class ThreadDetailRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ThreadDetailRouter();
  }

  static Widget detailAppBarTitle(Event event, ThemeData themeData) {
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> appBarTitleList = [];
    var nameComponnet = SimpleNameComponent(
      pubkey: event.pubKey,
      textStyle: TextStyle(
        fontSize: bodyLargeFontSize,
        color: themeData.appBarTheme.titleTextStyle!.color,
      ),
    );
    appBarTitleList.add(nameComponnet);
    appBarTitleList.add(Text(" : "));
    appBarTitleList.add(Expanded(
        child: Text(
      event.content.replaceAll("\n", " ").replaceAll("\r", " "),
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
    with PenddingEventsLaterFunction {
  EventMemBox box = EventMemBox();

  Event? sourceEvent;

  bool showTitle = false;

  ScrollController _controller = ScrollController();

  double rootEventHeight = 120;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.offset > rootEventHeight * 0.8 && !showTitle) {
        setState(() {
          showTitle = true;
        });
      } else if (_controller.offset < rootEventHeight * 0.8 && showTitle) {
        setState(() {
          showTitle = false;
        });
      }
    });
  }

  @override
  Widget doBuild(BuildContext context) {
    if (sourceEvent == null) {
      var obj = RouterUtil.routerArgs(context);
      if (obj != null && obj is Event) {
        sourceEvent = obj;
      }
      if (sourceEvent == null) {
        RouterUtil.back(context);
        return Container();
      }

      // do some init oper
      var eventRelation = EventRelation.fromEvent(sourceEvent!);
      rootId = eventRelation.rootId;
      if (rootId == null) {
        // source event is root event
        rootId = sourceEvent!.id;
        rootEvent = sourceEvent!;
      }

      // load sourceEvent replies and avoid blank page
      var eventReactions = eventReactionsProvider.get(sourceEvent!.id);
      if (eventReactions != null && eventReactions.replies.isNotEmpty) {
        box.addList(eventReactions.replies);
      } else if (rootId != null) {
        box.add(sourceEvent!);
      }
      listToTree(refresh: false);
    }

    // if (rootSubList == null || rootSubList!.isEmpty) {
    //   return Scaffold(
    //     body: Center(
    //       child: Text("Thread Detail"),
    //     ),
    //   );
    // }
    var themeData = Theme.of(context);
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    var cardColor = themeData.cardColor;

    // var currentEvent = rootEvent;
    // currentEvent ??= sourceEvent;

    Widget? appBarTitle;
    if (showTitle && rootEvent != null) {
      appBarTitle = ThreadDetailRouter.detailAppBarTitle(rootEvent!, themeData);
    }

    Widget? rootEventWidget;
    if (rootEvent == null) {
      rootEventWidget = Container(
        margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        color: cardColor,
        height: 60,
        child: Center(child: Text("Note loading...")),
      );
    } else {
      rootEventWidget = EventListComponent(
        event: rootEvent!,
        jumpable: false,
        showVideo: true,
      );
    }

    var main = NestedScrollView(
      controller: _controller,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return <Widget>[
          SliverToBoxAdapter(
            child: WidgetSize(
              child: rootEventWidget!,
              onChange: (size) {
                rootEventHeight = size.height;
              },
            ),
          ),
        ];
      },
      body: ListView.builder(
        itemBuilder: (context, index) {
          var item = rootSubList![index];
          return ThreadDetailItemComponent(item: item);
        },
        itemCount: rootSubList!.length,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(Icons.arrow_back_ios),
        ),
        // actions: [
        //   IconButton(
        //     onPressed: () {},
        //     icon: Icon(Icons.more_horiz),
        //   ),
        // ],
        title: appBarTitle,
      ),
      body: EventReplyCallback(
        child: main,
        onReplyCallback: onReplyCallback,
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    if (StringUtil.isNotBlank(rootId)) {
      if (rootEvent == null) {
        // source event isn't root event，query root event
        var filter = Filter(ids: [rootId!]);
        nostr!.pool.query([filter.toJson()], onRootEvent);
      }

      // query sub events
      var filter = Filter(e: [rootId!], kinds: [kind.EventKind.TEXT_NOTE]);
      nostr!.pool.query([filter.toJson()], onEvent);
    }
  }

  String? rootId;

  Event? rootEvent;

  List<ThreadDetailEvent>? rootSubList;

  void onRootEvent(Event event) {
    rootEvent = event;
  }

  void onEvent(Event event) {
    later(event, (list) {
      box.addList(list);
      listToTree();
      eventReactionsProvider.onEvents(list);
    }, null);
  }

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

    if (refresh) {
      setState(() {});
    }
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
