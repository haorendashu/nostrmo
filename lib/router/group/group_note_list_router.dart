import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/nip29/group_metadata.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/event/event_list_component.dart';
import '../../component/event_delete_callback.dart';
import '../../component/group_identifier_inherited_widget.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/group_details_provider.dart';
import '../../provider/group_provider.dart';
import '../../provider/setting_provider.dart';
import '../../util/load_more_event.dart';
import '../../util/router_util.dart';
import '../edit/editor_router.dart';

class GroupNoteListRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GroupNoteListRouter();
  }
}

class _GroupNoteListRouter extends State<GroupNoteListRouter>
    with LoadMoreEvent {
  ScrollController _controller = ScrollController();

  GroupIdentifier? groupIdentifier;

  EventMemBox? eventBox;

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var textColor = themeData.textTheme.bodyMedium!.color;
    var cardColor = themeData.cardColor;
    var s = S.of(context);

    var groupIdentifierItf = RouterUtil.routerArgs(context);
    if (groupIdentifierItf == null && groupIdentifierItf is! GroupIdentifier) {
      return Container();
    }
    groupIdentifier = groupIdentifierItf as GroupIdentifier;

    var _groupProvider = Provider.of<GroupProvider>(context);
    var groupAdmins = _groupProvider.getAdmins(groupIdentifier!);

    var _settingProvider = Provider.of<SettingProvider>(context);

    var nameComponnet = Selector<GroupProvider, GroupMetadata?>(
      builder: (BuildContext context, GroupMetadata? value, Widget? child) {
        String text = groupIdentifier!.groupId;
        if (value != null && StringUtil.isNotBlank(value.name)) {
          text = value.name!;
        }

        return Text(
          text,
          style: TextStyle(
            fontSize: themeData.textTheme.bodyLarge!.fontSize,
            fontWeight: FontWeight.bold,
          ),
        );
      },
      selector: (context, _provider) {
        return _provider.getMetadata(groupIdentifier!);
      },
    );

    List<Widget> list = [];

    var listWidget = Selector<GroupDetailsProvider, EventMemBox?>(
      builder: (context, _eventBox, child) {
        if (_eventBox == null) {
          return Container();
        }
        eventBox = _eventBox;
        preBuild();

        var events = eventBox!.all();

        return ListView.builder(
          controller: _controller,
          itemBuilder: (BuildContext context, int index) {
            var event = events[index];
            return EventListComponent(
              event: event,
              showVideo:
                  _settingProvider.videoPreviewInList != OpenStatus.CLOSE,
            );
          },
          itemCount: events.length,
        );
      },
      selector: (context, provider) {
        return provider.getNotesEventBox(groupIdentifier!);
      },
    );

    list.add(Expanded(
      child: listWidget,
    ));

    Widget main = Container(
      width: double.maxFinite,
      height: double.maxFinite,
      child: Column(children: list),
    );

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: nameComponnet,
        actions: [
          GestureDetector(
            onTap: jumpToAddNote,
            child: Container(
              margin: const EdgeInsets.only(
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
              ),
              child: Icon(
                Icons.add,
                color: themeData.appBarTheme.titleTextStyle!.color,
              ),
            ),
          )
        ],
      ),
      body: EventDeleteCallback(
        onDeleteCallback: onEventDelete,
        child: DefaultTabController(
          length: 2,
          child: GroupIdentifierInheritedWidget(
            key: Key("GD_${groupIdentifier.toString()}"),
            groupIdentifier: groupIdentifier!,
            groupAdmins: groupAdmins,
            child: main,
          ),
        ),
      ),
    );
  }

  void jumpToAddNote() {
    List<dynamic> tags = [];

    if (eventBox != null) {
      var previous = GroupDetailsProvider.getTimelinePrevious(eventBox!);
      if (previous.isNotEmpty) {
        var previousTag = ["previous", ...previous];
        tags.add(previousTag);
      }
    }

    EditorRouter.open(context,
        groupIdentifier: groupIdentifier,
        groupEventKind: EventKind.GROUP_NOTE,
        tagsAddedWhenSend: tags);
  }

  @override
  void doQuery() {
    preQuery();

    if (eventBox != null && groupIdentifier != null && until != null) {
      groupDetailsProvider.queryGroupEvents(
          groupIdentifier!, until!, GroupDetailsProvider.supportNoteKinds);
    }
  }

  @override
  EventMemBox getEventBox() {
    return eventBox!;
  }

  void onEventDelete(Event e) {
    if (eventBox != null) {
      eventBox!.delete(e.id);
    }
  }
}
