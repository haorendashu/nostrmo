import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:widget_size/widget_size.dart';

import '../../client/event.dart';
import '../../client/event_kind.dart' as kind;
import '../../component/event/event_list_component.dart';
import '../../component/event/event_load_list_component.dart';
import '../../component/event/reaction_event_list_component.dart';
import '../../component/event/zap_event_list_component.dart';
import '../../data/event_reactions.dart';
import '../../generated/l10n.dart';
import '../../provider/event_reactions_provider.dart';
import '../../provider/single_event_provider.dart';
import '../../util/platform_util.dart';
import '../../util/router_util.dart';
import '../thread/thread_detail_router.dart';

class EventDetailRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _EventDetailRouter();
  }
}

class _EventDetailRouter extends State<EventDetailRouter> {
  String? eventId;

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
    var s = S.of(context);

    var arg = RouterUtil.routerArgs(context);
    if (arg != null) {
      if (arg is Event) {
        event = arg;
        eventId = event!.id;
      } else if (arg is String) {
        event = null;
        eventId = arg;
      }
    }
    if (event == null && eventId == null) {
      RouterUtil.back(context);
      return Container();
    }
    var themeData = Theme.of(context);

    Widget? appBarTitle;
    if (showTitle && event != null) {
      appBarTitle = ThreadDetailRouter.detailAppBarTitle(event!, themeData);
    }

    Widget? mainEventWidget;
    if (event != null) {
      mainEventWidget = EventListComponent(
        event: event!,
        showVideo: true,
        showDetailBtn: false,
      );
    } else if (eventId != null) {
      mainEventWidget = Selector<SingleEventProvider, Event?>(
        builder: (context, _event, child) {
          if (_event == null) {
            return EventLoadListComponent();
          } else {
            event = _event;
            return EventListComponent(
              event: _event,
              showVideo: true,
              showDetailBtn: false,
            );
          }
        },
        selector: (context, _provider) {
          return _provider.getEvent(eventId!);
        },
      );
    }

    var mainWidget = Selector<EventReactionsProvider, EventReactions?>(
      builder: (context, eventReactions, child) {
        if (eventReactions == null) {
          return mainEventWidget!;
        }

        List<Event> allEvent = [];
        allEvent.addAll(eventReactions.replies);
        allEvent.addAll(eventReactions.reposts);
        allEvent.addAll(eventReactions.likes);
        allEvent.addAll(eventReactions.zaps);
        allEvent.sort((event1, event2) {
          return event2.createdAt - event1.createdAt;
        });

        Widget main = ListView.builder(
          controller: _controller,
          itemBuilder: (context, index) {
            if (index == 0) {
              return WidgetSize(
                child: mainEventWidget!,
                onChange: (size) {
                  rootEventHeight = size.height;
                },
              );
            }

            var event = allEvent[index - 1];
            if (event.kind == kind.EventKind.ZAP) {
              return ZapEventListComponent(event: event);
            } else if (event.kind == kind.EventKind.TEXT_NOTE) {
              return ReactionEventListComponent(event: event, text: s.replied);
            } else if (event.kind == kind.EventKind.REPOST ||
                event.kind == kind.EventKind.GENERIC_REPOST) {
              return ReactionEventListComponent(event: event, text: s.boosted);
            } else if (event.kind == kind.EventKind.REACTION) {
              return ReactionEventListComponent(event: event, text: s.liked);
            }

            return Container();
          },
          itemCount: allEvent.length + 1,
        );

        if (PlatformUtil.isTableMode()) {
          main = GestureDetector(
            onVerticalDragUpdate: (detail) {
              _controller.jumpTo(_controller.offset - detail.delta.dy);
            },
            behavior: HitTestBehavior.translucent,
            child: main,
          );
        }

        return main;
      },
      selector: (context, _provider) {
        return _provider.get(eventId!);
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
          child: Icon(
            Icons.arrow_back_ios,
            color: themeData.appBarTheme.titleTextStyle!.color,
          ),
        ),
        title: appBarTitle,
      ),
      body: mainWidget,
    );
  }
}
