import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:provider/provider.dart';

import '../../consts/base_consts.dart';
import '../../provider/setting_provider.dart';
import '../../util/load_more_event.dart';
import '../../util/table_mode_util.dart';
import 'list_event_component.dart';

/// A event list (mang events not single event) component.
class EventListComponent extends StatefulWidget {
  List<Event> events;

  ScrollController scrollController;

  Function()? onRefresh;

  EventListComponent(
    this.events,
    this.scrollController, {
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

    var main = ListView.builder(
      controller: widget.scrollController,
      itemBuilder: (BuildContext context, int index) {
        // var event = events[index];
        // return FrameSeparateWidget(
        //   index: index,
        //   child: ListEventComponent(
        //     event: event,
        //   ),
        // );
        var event = events[index];
        return ListEventComponent(
          event: event,
          showVideo: _settingProvider.videoPreviewInList != OpenStatus.CLOSE,
        );
      },
      itemCount: events.length,
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
