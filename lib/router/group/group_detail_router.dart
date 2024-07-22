import 'package:flutter/material.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/client/nip29/group_identifier.dart';
import 'package:nostrmo/component/image_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';

import '../../client/filter.dart';
import '../../component/appbar_back_btn_component.dart';
import '../../generated/l10n.dart';

class GroupDetailRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GroupDetailRouter();
  }
}

class _GroupDetailRouter extends State<GroupDetailRouter> {
  GroupIdentifier? groupIdentifier;

  static const APP_BAR_HEIGHT = 40.0;

  @override
  Widget build(BuildContext context) {
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
    if (groupIdentifier == null ||
        groupIdentifier.toString() != (argIntf as GroupIdentifier).toString()) {
      loadData();
    }
    groupIdentifier = argIntf as GroupIdentifier?;

    var _groupMetadataProvider = Provider.of<GroupProvider>(context);
    var groupMetadata = _groupMetadataProvider.getMetadata(groupIdentifier!);
    String title = "GroupDetail";
    Widget flexBackground = Container(
      color: themeData.hintColor.withOpacity(0.3),
    );
    if (groupMetadata != null) {
      if (StringUtil.isNotBlank(groupMetadata.name)) {
        title = groupMetadata.name!;
      }
      Widget? desWidget;
      if (StringUtil.isNotBlank(groupMetadata.about)) {
        desWidget = Text(
          groupMetadata.about!,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        );
      }
      if (StringUtil.isNotBlank(groupMetadata.picture)) {
        flexBackground = flexBackground = Container(
          decoration: BoxDecoration(
            color: themeData.hintColor.withOpacity(0.3),
            image: DecorationImage(
                image: NetworkImage(groupMetadata.picture!), fit: BoxFit.fill),
          ),
          padding: EdgeInsets.only(
            top: 14 + mediaQuery.padding.top + 46,
            left: 20,
            right: 20,
            bottom: APP_BAR_HEIGHT + 14,
          ),
          child: desWidget,
        );
      }
    }

    List<Widget> tabs = [
      Container(
        height: APP_BAR_HEIGHT,
        alignment: Alignment.center,
        child: Text("Notes"),
      ),
      Container(
        height: APP_BAR_HEIGHT,
        alignment: Alignment.center,
        child: Text("Chat"),
      ),
    ];

    var appbar = SliverAppBar(
      floating: false,
      snap: false,
      pinned: true,
      primary: true,
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
        background: flexBackground,
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
          onTap: () {},
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

    var main = SliverFillRemaining(
      child: TabBarView(
        children: [
          Container(
            color: Colors.pink.withOpacity(0.2),
            child: Text("Notes"),
          ),
          Container(
            color: Colors.redAccent.withOpacity(0.2),
            child: Text("Chat"),
          ),
        ],
      ),
    );

    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: CustomScrollView(
          slivers: [
            appbar,
            main,
          ],
        ),
      ),
    );
  }

  void loadData() {
    if (groupIdentifier != null) {
      var relays = [groupIdentifier!.host];
      var filter = Filter(kinds: [
        EventKind.GROUP_NOTE,
        EventKind.GROUP_NOTE_REPLY,
        EventKind.GROUP_CHAT_MESSAGE,
        EventKind.GROUP_CHAT_REPLY,
      ]);
      nostr!.query(
        [filter.toJson()],
        onEvent,
        tempRelays: relays,
        onlyTempRelays: true,
        queryLocal: false,
      );
    }
  }

  onEvent(Event e) {
    print(e.toJson());
  }
}
