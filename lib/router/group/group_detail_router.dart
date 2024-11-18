import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/event_delete_callback.dart';
import 'package:nostrmo/component/group_identifier_inherited_widget.dart';
import 'package:nostrmo/component/image_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/router/edit/editor_router.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/cust_state.dart';
import '../../generated/l10n.dart';
import 'group_detail_chat_component.dart';
import 'group_detail_note_list_component.dart';

class GroupDetailRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GroupDetailRouter();
  }
}

class _GroupDetailRouter extends CustState<GroupDetailRouter> {
  GroupIdentifier? groupIdentifier;

  static const APP_BAR_HEIGHT = 40.0;

  GroupDetailProvider groupDetailProvider = GroupDetailProvider();

  @override
  void initState() {
    super.initState();
    groupDetailProvider.startQueryTask();
  }

  @override
  void dispose() {
    super.dispose();
    groupDetailProvider.dispose();
  }

  @override
  Future<void> onReady(BuildContext context) async {}

  double imageWidth = 50;

  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var s = S.of(context);
    var appbarColor = themeData.appBarTheme.titleTextStyle!.color;
    var mainColor = themeData.primaryColor;
    var mediaQuery = MediaQuery.of(context);

    var argIntf = RouterUtil.routerArgs(context);
    if (argIntf == null || argIntf is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }
    groupIdentifier = argIntf as GroupIdentifier?;
    groupDetailProvider.updateGroupIdentifier(groupIdentifier!);

    var _groupProvider = Provider.of<GroupProvider>(context);
    var groupMetadata = _groupProvider.getMetadata(groupIdentifier!);
    var groupAdmins = _groupProvider.getAdmins(groupIdentifier!);
    String title = "${s.Group} ${s.Detail}";
    Widget imageWidget = Container(
      width: imageWidth,
      height: imageWidth,
    );
    Widget desWidget = Container();
    if (groupMetadata != null) {
      if (StringUtil.isNotBlank(groupMetadata.name)) {
        title = groupMetadata.name!;
      }
      if (StringUtil.isNotBlank(groupMetadata.about)) {
        desWidget = Text(
          groupMetadata.about!,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        );
      }
      if (StringUtil.isNotBlank(groupMetadata.picture)) {
        imageWidget = Container(
          width: imageWidth,
          height: imageWidth,
          margin: const EdgeInsets.only(
            top: Base.BASE_PADDING_HALF,
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
          ),
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(imageWidth / 2),
          ),
          child: ImageComponent(imageUrl: groupMetadata.picture!),
        );
        // flexBackground = flexBackground = Container(
        //   decoration: BoxDecoration(
        //     color: themeData.hintColor.withOpacity(0.3),
        //     image: DecorationImage(
        //         image: NetworkImage(groupMetadata.picture!), fit: BoxFit.fill),
        //   ),
        //   padding: EdgeInsets.only(
        //     top: 14 + mediaQuery.padding.top + 46,
        //     left: 20,
        //     right: 20,
        //     bottom: APP_BAR_HEIGHT + 14,
        //   ),
        //   child: desWidget,
        // );
      }
    }

    List<Widget> tabs = [
      Container(
        height: APP_BAR_HEIGHT,
        alignment: Alignment.center,
        child: Text(s.Notes),
      ),
      Container(
        height: APP_BAR_HEIGHT,
        alignment: Alignment.center,
        child: Text(s.Chat),
      ),
    ];

    var appbar = SliverAppBar(
      // floating: false,
      // snap: false,
      pinned: true,
      // primary: true,
      expandedHeight: 200,
      leading: AppbarBackBtnComponent(),
      title: Text(
        title,
        style: TextStyle(
          fontSize: bodyLargeFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          padding: EdgeInsets.only(top: 60),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [imageWidget, Expanded(child: desWidget)],
          ),
        ),
      ),
      bottom: TabBar(
        tabs: tabs,
        labelColor: mainColor,
        indicatorWeight: 3,
        indicatorColor: mainColor,
        unselectedLabelColor: themeData.textTheme.bodyMedium!.color,
      ),
      actions: [
        GestureDetector(
          onTap: jumpToAddNote,
          child: Container(
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING_HALF,
              right: Base.BASE_PADDING,
            ),
            child: Icon(
              Icons.add,
              color: themeData.appBarTheme.titleTextStyle!.color,
            ),
          ),
        ),
      ],
    );

    // var main = SliverFillRemaining(
    //   child: MultiProvider(
    //     providers: [
    //       ListenableProvider<GroupDetailProvider>.value(
    //         value: groupDetailProvider,
    //       ),
    //     ],
    //     child: TabBarView(
    //       children: [
    //         GroupDetailNoteListComponent(groupIdentifier!),
    //         GroupDetailChatComponent(groupIdentifier!),
    //       ],
    //     ),
    //   ),
    // );

    final double statusBarHeight = MediaQuery.of(context).padding.top;
    var pinnedHeaderHeight =
        //statusBar height
        statusBarHeight +
            //pinned SliverAppBar height in header
            kToolbarHeight;

    return Scaffold(
      body: EventDeleteCallback(
        onDeleteCallback: onEventDelete,
        child: DefaultTabController(
          length: 2,
          child: GroupIdentifierInheritedWidget(
            key: Key("GD_${groupIdentifier.toString()}"),
            groupIdentifier: groupIdentifier!,
            groupAdmins: groupAdmins,
            child: MultiProvider(
              providers: [
                ListenableProvider<GroupDetailProvider>.value(
                  value: groupDetailProvider,
                ),
              ],
              child: ExtendedNestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    appbar,
                  ];
                },
                // onlyOneScrollInBody: true,
                pinnedHeaderSliverHeightBuilder: () {
                  return pinnedHeaderHeight;
                },
                body: Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        children: [
                          GroupDetailNoteListComponent(groupIdentifier!),
                          GroupDetailChatComponent(groupIdentifier!),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void jumpToAddNote() {
    List<dynamic> tags = [];
    var previousTag = ["previous", ...groupDetailProvider.notesPrevious()];
    tags.add(previousTag);
    EditorRouter.open(context,
        groupIdentifier: groupIdentifier,
        groupEventKind: EventKind.GROUP_NOTE,
        tagsAddedWhenSend: tags);
  }

  void onEventDelete(Event e) {
    groupDetailProvider.deleteEvent(e);
  }
}
