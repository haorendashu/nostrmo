import 'package:flutter/material.dart';
import 'package:nostrmo/component/event_delete_callback.dart';
import 'package:nostrmo/router/tag/topic_map.dart';
import 'package:provider/provider.dart';

import '../../client/event.dart';
import '../../client/filter.dart';
import '../../component/cust_state.dart';
import '../../component/event/event_list_component.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../data/event_mem_box.dart';
import '../../main.dart';
import '../../provider/setting_provider.dart';
import '../../util/peddingevents_later_function.dart';
import '../../util/platform_util.dart';
import '../../util/router_util.dart';
import '../../client/event_kind.dart' as kind;
import '../../util/string_util.dart';

class TagDetailRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TagDetailRouter();
  }
}

class _TagDetailRouter extends CustState<TagDetailRouter>
    with PenddingEventsLaterFunction {
  EventMemBox box = EventMemBox();

  ScrollController _controller = ScrollController();

  bool showTitle = false;

  double tagHeight = 80;

  String? tag;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.offset > tagHeight * 0.8 && !showTitle) {
        setState(() {
          showTitle = true;
        });
      } else if (_controller.offset < tagHeight * 0.8 && showTitle) {
        setState(() {
          showTitle = false;
        });
      }
    });
  }

  @override
  Widget doBuild(BuildContext context) {
    var _settingProvider = Provider.of<SettingProvider>(context);
    if (StringUtil.isBlank(tag)) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is String) {
        tag = arg;
      }
    } else {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is String && tag != arg) {
        // arg changed! reset
        tag = arg;

        box = EventMemBox();
        doQuery();
      }
    }
    if (StringUtil.isBlank(tag)) {
      RouterUtil.back(context);
      return Container();
    }

    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    Widget? appBarTitle;
    if (showTitle) {
      appBarTitle = Text(
        tag!,
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
            return Container(
              height: tagHeight,
              color: cardColor,
              alignment: Alignment.center,
              margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
              child: Text(
                tag!,
                style: TextStyle(
                  fontSize: bodyLargeFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          var event = box.get(index - 1);
          if (event == null) {
            return null;
          }

          return EventListComponent(
            event: event,
            showVideo: _settingProvider.videoPreviewInList == OpenStatus.OPEN,
          );
        },
        itemCount: box.length() + 1,
      ),
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

  var subscribeId = StringUtil.rndNameStr(16);

  @override
  Future<void> onReady(BuildContext context) async {
    doQuery();
  }

  void doQuery() {
    // tag query
    // https://github.com/nostr-protocol/nips/blob/master/12.md
    var filter = Filter(kinds: [
      kind.EventKind.TEXT_NOTE,
      kind.EventKind.LONG_FORM,
      kind.EventKind.FILE_HEADER,
      kind.EventKind.POLL,
    ], limit: 100);
    var queryArg = filter.toJson();
    var plainTag = tag!.replaceFirst("#", "");
    // this place set #t not #r ???
    var list = TopicMap.getList(plainTag);
    if (list != null) {
      queryArg["#t"] = list;
    } else {
      queryArg["#t"] = [plainTag];
    }
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
}
