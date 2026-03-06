import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../consts/base_consts.dart';
import '../../provider/setting_provider.dart';
import '../../util/table_mode_util.dart';
import 'list_event_component.dart';

/// A event list (mang events not single event) component.
class EventListComponent extends StatefulWidget {
  EventMemBox eventBox;

  ItemScrollController itemScrollController;
  ScrollOffsetController scrollOffsetController;
  ItemPositionsListener itemPositionsListener;
  ScrollOffsetListener scrollOffsetListener;

  Function()? onRefresh;

  EventListComponent(
    this.eventBox,
    this.itemScrollController,
    this.scrollOffsetController,
    this.itemPositionsListener,
    this.scrollOffsetListener, {
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

    var main = ScrollablePositionedList.builder(
      itemCount: widget.eventBox.length(),
      itemBuilder: (context, index) {
        var event = widget.eventBox.get(index);
        if (event == null) {
          return Container();
        }

        return ListEventComponent(
          event: event,
          showVideo: _settingProvider.videoPreviewInList != OpenStatus.CLOSE,
        );
      },
      itemScrollController: widget.itemScrollController,
      scrollOffsetController: widget.scrollOffsetController,
      itemPositionsListener: widget.itemPositionsListener,
      scrollOffsetListener: widget.scrollOffsetListener,
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
          widget.scrollOffsetController.animateScroll(
              offset: -detail.delta.dy * 3.5,
              duration: const Duration(microseconds: 1));
        },
        behavior: HitTestBehavior.translucent,
        child: ri,
      );
    }

    return ri;
  }
}
