import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:provider/provider.dart';
import 'package:widget_size/widget_size.dart';

import '../../client/event_kind.dart' as kind;
import '../../component/event/event_list_component.dart';
import '../../component/event/reaction_event_list_component.dart';
import '../../component/event/zap_event_list_component.dart';
import '../../data/event_reactions.dart';
import '../../provider/event_reactions_provider.dart';
import '../../util/router_util.dart';
import '../thread/thread_detail_router.dart';

class EventDetailRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _EventDetailRouter();
  }
}

class _EventDetailRouter extends State<EventDetailRouter> {
  Event? event;

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
  Widget build(BuildContext context) {
    if (event == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is Event) {
        event = arg;
      }
    }
    if (event == null) {
      RouterUtil.back(context);
      return Container();
    }
    var themeData = Theme.of(context);

    Widget? appBarTitle;
    if (showTitle) {
      appBarTitle = ThreadDetailRouter.detailAppBarTitle(event!, themeData);
    }

    var mainWidget = Selector<EventReactionsProvider, EventReactions?>(
      builder: (context, eventReactions, child) {
        var mainEventWidget = EventListComponent(
          event: event!,
          showVideo: true,
        );
        if (eventReactions == null) {
          return mainEventWidget;
        }

        List<Event> allEvent = [];
        allEvent.addAll(eventReactions.replies);
        allEvent.addAll(eventReactions.reposts);
        allEvent.addAll(eventReactions.likes);
        allEvent.addAll(eventReactions.zaps);
        allEvent.sort((event1, event2) {
          return event2.createdAt - event1.createdAt;
        });

        var main = NestedScrollView(
          controller: _controller,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return <Widget>[
              SliverToBoxAdapter(
                child: WidgetSize(
                  child: mainEventWidget,
                  onChange: (size) {
                    rootEventHeight = size.height;
                  },
                ),
              ),
            ];
          },
          body: ListView.builder(
            itemBuilder: (context, index) {
              var event = allEvent[index];
              if (event.kind == kind.EventKind.ZAP) {
                return ZapEventListComponent(event: event);
              } else if (event.kind == kind.EventKind.TEXT_NOTE) {
                return ReactionEventListComponent(
                    event: event, text: "replied");
              } else if (event.kind == kind.EventKind.REPOST) {
                return ReactionEventListComponent(
                    event: event, text: "boosted");
              } else if (event.kind == kind.EventKind.REACTION) {
                return ReactionEventListComponent(event: event, text: "liked");
              }

              return Container();
            },
            itemCount: allEvent.length,
          ),
        );

        return main;
      },
      selector: (context, _provider) {
        return _provider.get(event!.id);
      },
      shouldRebuild: (previous, next) {
        if ((previous == null && next != null) ||
            (previous != null &&
                next != null &&
                (previous.replies.length != next.replies.length ||
                    previous.repostNum != next.repostNum ||
                    previous.likeNum != next.likeNum ||
                    previous.zapNum != next.zapNum))) {
          return true;
        }

        return false;
      },
    );

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(Icons.arrow_back_ios),
        ),
        title: appBarTitle,
      ),
      body: mainWidget,
    );
  }
}
