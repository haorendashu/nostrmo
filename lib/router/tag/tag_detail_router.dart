import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostrmo/component/event_delete_callback.dart';
import 'package:nostrmo/router/tag/topic_map.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/cust_state.dart';
import '../../component/event/event_list_component.dart';
import '../../component/tag_info_component.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../consts/event_kind_type.dart';
import '../../main.dart';
import '../../provider/setting_provider.dart';
import '../../util/router_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../../util/table_mode_util.dart';

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
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    Widget? appBarTitle;
    if (showTitle) {
      appBarTitle = Text(
        "#${tag!}",
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
            return TagInfoComponent(
              tag: tag!,
              height: tagHeight,
            );
          }

          var event = box.get(index - 1);
          if (event == null) {
            return null;
          }

          return ListEventComponent(
            event: event,
            showVideo: _settingProvider.videoPreviewInList != OpenStatus.CLOSE,
          );
        },
        itemCount: box.length() + 1,
      ),
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
    var filter = Filter(kinds: EventKindType.SUPPORTED_EVENTS, limit: 100);
    var queryArg = filter.toJson();
    var plainTag = tag!.replaceFirst("#", "");
    // this place set #t not #r ???
    var list = TopicMap.getList(plainTag);
    if (list != null) {
      queryArg["#t"] = list;
    } else {
      // can't find from topicMap, change to query the source, upperCase and lowerCase
      var upperCase = plainTag.toUpperCase();
      var lowerCase = plainTag.toLowerCase();
      list = [upperCase];
      if (upperCase != lowerCase) {
        list.add(lowerCase);
      }
      if (upperCase != plainTag && lowerCase != plainTag) {
        list.add(plainTag);
      }
      queryArg["#t"] = list;
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
