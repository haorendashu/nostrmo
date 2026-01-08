import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/util/table_mode_util.dart';
import 'package:provider/provider.dart';
import 'package:widget_size/widget_size.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/event/event_list_component.dart';
import '../../component/event/event_load_list_component.dart';
import '../../component/event/reaction_event_list_component.dart';
import '../../component/event/zap_event_list_component.dart';
import '../../data/event_reactions.dart';
import '../../generated/l10n.dart';
import '../../provider/event_reactions_provider.dart';
import '../../provider/single_event_provider.dart';
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
    if (event != null) {
      titlePubkey = event!.pubkey;
      title = ThreadDetailRouter.getAppBarTitle(event!);
    }
    if (showTitle) {
      if (StringUtil.isNotBlank(titlePubkey) && StringUtil.isNotBlank(title)) {
        appBarTitle = ThreadDetailRouter.detailAppBarTitle(
            titlePubkey!, title!, themeData);
      }
    }

    Widget? mainEventWidget;
    if (event != null) {
      mainEventWidget = ListEventComponent(
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
            titlePubkey = event!.pubkey;
            title = ThreadDetailRouter.getAppBarTitle(event!);
            return ListEventComponent(
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
            if (event.kind == EventKind.ZAP) {
              return ZapListEventComponent(event: event);
            } else if (event.kind == EventKind.TEXT_NOTE) {
              return ReactionListEventComponent(event: event, text: s.replied);
            } else if (event.kind == EventKind.REPOST ||
                event.kind == EventKind.GENERIC_REPOST) {
              return ReactionListEventComponent(event: event, text: s.boosted);
            } else if (event.kind == EventKind.REACTION) {
              return ReactionListEventComponent(
                  event: event,
                  text: s.liked + " " + EventReactions.getLikeText(event));
            }

            return Container();
          },
          itemCount: allEvent.length + 1,
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
        leading: AppbarBackBtnComponent(),
        title: appBarTitle,
      ),
      body: mainWidget,
    );
  }
}
