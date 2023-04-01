import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../provider/index_provider.dart';
import '../../provider/setting_provider.dart';
import '../dm/dm_router.dart';
import '../edit/editor_router.dart';
import '../follow/follow_index_router.dart';
import '../globals/globals_index_router.dart';
import '../login/login_router.dart';
import '../search/search_router.dart';
import 'index_app_bar.dart';
import 'index_bottom_bar.dart';
import 'index_drawer_content.dart';

class IndexRouter extends StatefulWidget {
  Function reload;

  IndexRouter({required this.reload});

  @override
  State<StatefulWidget> createState() {
    return _IndexRouter();
  }
}

class _IndexRouter extends State<IndexRouter> with TickerProviderStateMixin {
  late TabController followTabController;

  late TabController globalsTabController;

  late TabController dmTabController;

  @override
  void initState() {
    super.initState();
    followTabController = TabController(length: 3, vsync: this);
    globalsTabController = TabController(length: 3, vsync: this);
    dmTabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    mediaDataCache.update(context);

    var _settingProvider = Provider.of<SettingProvider>(context);
    if (nostr == null) {
      return LoginRouter();
    }
    var _indexProvider = Provider.of<IndexProvider>(context);
    _indexProvider.setFollowTabController(followTabController);
    var themeData = Theme.of(context);
    var titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    var titleTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: titleTextColor,
    );

    Widget? appBarCenter;
    if (_indexProvider.currentTap == 0) {
      appBarCenter = TabBar(
        tabs: [
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text("Posts"),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(
              "Posts & Replies",
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text("Mentions"),
          ),
        ],
        controller: followTabController,
      );
    } else if (_indexProvider.currentTap == 1) {
      appBarCenter = TabBar(
        tabs: [
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text("Notes"),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text("Users"),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text("Topics"),
          ),
        ],
        controller: globalsTabController,
      );
    } else if (_indexProvider.currentTap == 2) {
      appBarCenter = Center(
        child: Text(
          "Search",
          style: titleTextStyle,
        ),
      );
    } else if (_indexProvider.currentTap == 3) {
      appBarCenter = TabBar(
        tabs: [
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text("DMs"),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text("Request"),
          ),
        ],
        controller: dmTabController,
      );
    }
    // else if (_indexProvider.currentTap == 3) {
    //   appBarCenter = Center(
    //     child: Text(
    //       "Notice",
    //       style: titleTextStyle,
    //     ),
    //   );
    // }

    return Scaffold(
      body: Column(
        children: [
          IndexAppBar(
            center: appBarCenter,
          ),
          MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Expanded(
                child: IndexedStack(
              index: _indexProvider.currentTap,
              children: [
                FollowIndexRouter(
                  tabController: followTabController,
                ),
                GlobalsIndexRouter(
                  tabController: globalsTabController,
                ),
                SearchRouter(),
                DMRouter(
                  tabController: dmTabController,
                ),
                // NoticeRouter(),
              ],
            )),
          ),
          // IndexBottomBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          EditorRouter.open(context);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      drawer: Drawer(
        child: IndexDrawerContnetComponnent(),
      ),
      bottomNavigationBar: IndexBottomBar(),
    );
  }
}
