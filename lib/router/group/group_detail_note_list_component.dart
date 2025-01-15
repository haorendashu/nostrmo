import 'package:flutter/material.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:provider/provider.dart';

import '../../component/event/event_list_component.dart';
import '../../component/events_loading_more_repo.dart';
import '../../component/keep_alive_cust_state.dart';
import '../../component/new_notes_updated_component.dart';
import '../../component/placeholder/event_list_placeholder.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../provider/setting_provider.dart';
import '../../util/load_more_event.dart';

@Deprecated("Use GroupNoteListRouter instead")
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
    with PenddingEventsLaterFunction {
  ClampingScrollPhysics scrollPhysics = ClampingScrollPhysics();

  EventsLoadingMoreRepo eventsLoadingMoreRepo = EventsLoadingMoreRepo();

  @override
  void initState() {
    super.initState();

    eventsLoadingMoreRepo.getEventBox = getEventBox;
    eventsLoadingMoreRepo.doQuery = doQuery;
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

    Widget main = LoadingMoreList<Event>(ListConfig<Event>(
      itemBuilder: (BuildContext context, Event event, int index) {
        return EventListComponent(
          event: event,
          showVideo: _settingProvider.videoPreviewInList != OpenStatus.CLOSE,
        );
      },
      sourceList: eventsLoadingMoreRepo,
    ));

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
          // scrollController.jumpTo(0);
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
  Future<void> onReady(BuildContext context) async {
    eventsLoadingMoreRepo.loadData();
  }

  Future<void> doQuery() async {
    groupDetailProvider!.doQueryNotes(eventsLoadingMoreRepo.until);
  }

  EventMemBox getEventBox() {
    return groupDetailProvider!.notesBox;
  }

  Future<void> onRefresh() async {
    groupDetailProvider!.refresh();
  }
}
