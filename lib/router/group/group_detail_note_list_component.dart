import 'package:flutter/material.dart';
import 'package:nostrmo/data/event_mem_box.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:provider/provider.dart';

import '../../client/nip29/group_identifier.dart';
import '../../component/event/event_list_component.dart';
import '../../component/keep_alive_cust_state.dart';
import '../../component/new_notes_updated_component.dart';
import '../../component/placeholder/event_list_placeholder.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../provider/setting_provider.dart';
import '../../util/load_more_event.dart';
import '../../util/peddingevents_later_function.dart';

class GroupDetailNoteListComponent extends StatefulWidget {
  final GroupIdentifier groupIdentifier;

  GroupDetailNoteListComponent(this.groupIdentifier);

  @override
  State<StatefulWidget> createState() {
    return _GroupDetailNoteListComponent();
  }
}

class _GroupDetailNoteListComponent
    extends KeepAliveCustState<GroupDetailNoteListComponent>
    with LoadMoreEvent, PenddingEventsLaterFunction {
  final ScrollController _controller = ScrollController();

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
  }

  GroupDetailProvider? groupDetailProvider;

  @override
  Widget doBuild(BuildContext context) {
    var _settingProvider = Provider.of<SettingProvider>(context);
    groupDetailProvider = Provider.of<GroupDetailProvider>(context);

    var eventBox = groupDetailProvider!.notesBox;
    var events = eventBox.all();
    if (events.isEmpty) {
      return EventListPlaceholder(
        onRefresh: onRefresh,
      );
    }
    preBuild();

    var main = Container(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          controller: scrollController,
          itemBuilder: (context, index) {
            var event = events[index];
            return EventListComponent(
              event: event,
              showVideo:
                  _settingProvider.videoPreviewInList != OpenStatus.CLOSE,
            );
          },
          itemCount: events.length,
        ),
      ),
    );

    var newNotesLength = groupDetailProvider!.newNotesBox.length();
    if (newNotesLength <= 0) {
      return main;
    }

    List<Widget> stackList = [main];
    stackList.add(Positioned(
      top: Base.BASE_PADDING,
      child: NewNotesUpdatedComponent(
        num: newNotesLength,
        onTap: () {
          groupDetailProvider!.mergeNewEvent();
          scrollController.jumpTo(0);
        },
      ),
    ));

    return Container(
      child: Stack(
        alignment: Alignment.center,
        children: stackList,
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {}

  @override
  void doQuery() {
    preQuery();
    groupDetailProvider!.doQuery(until);
  }

  @override
  EventMemBox getEventBox() {
    return groupDetailProvider!.notesBox;
  }

  Future<void> onRefresh() async {
    groupDetailProvider!.refresh();
  }
}
