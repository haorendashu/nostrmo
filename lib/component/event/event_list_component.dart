import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:provider/provider.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import '../../consts/base_consts.dart';
import '../../provider/setting_provider.dart';
import '../../util/load_more_event.dart';
import '../../util/table_mode_util.dart';
import 'list_event_component.dart';

/// A event list (mang events not single event) component.
class EventListComponent extends StatefulWidget {
  List<Event> events;

  ScrollController scrollController;

  ListObserverController listObserverController;

  Function()? onRefresh;

  EventListComponent(
    this.events,
    this.scrollController,
    this.listObserverController, {
    this.onRefresh,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventListComponent();
  }
}

class _EventListComponent extends State<EventListComponent> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var _settingProvider = Provider.of<SettingProvider>(context);
    var events = widget.events;

    var main = ListViewObserver(
      controller: widget.listObserverController,
      child: ListView.builder(
        controller: widget.scrollController,
        itemBuilder: (BuildContext context, int index) {
          var event = events[index];
          return ListEventComponent(
            event: event,
            showVideo: _settingProvider.videoPreviewInList != OpenStatus.CLOSE,
          );
        },
        itemCount: events.length,
      ),
      onObserve: (model) {
        // 打印当前正在显示的第一个子部件
        print('firstChild.index -- ${model.firstChild?.index}');

        // 打印当前正在显示的所有子部件下标
        print('displaying -- ${model.displayingChildIndexList}');
      },
    );

    Widget ri = RefreshIndicator(
      onRefresh: () async {
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }
      },
      child: main,
    );

    if (TableModeUtil.isTableMode()) {
      ri = GestureDetector(
        onVerticalDragUpdate: (detail) {
          widget.scrollController
              .jumpTo(widget.scrollController.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: ri,
      );
    }

    return ri;
  }
}
