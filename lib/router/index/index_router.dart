import 'package:flutter/material.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/index_provider.dart';
import '../../provider/setting_provider.dart';
import '../../util/auth_util.dart';
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

class _IndexRouter extends CustState<IndexRouter>
    with TickerProviderStateMixin {
  late TabController followTabController;

  late TabController globalsTabController;

  late TabController dmTabController;

  @override
  void initState() {
    super.initState();
    int followInitTab = 0;
    int globalsInitTab = 0;

    if (settingProvider.defaultTab != null) {
      if (settingProvider.defaultIndex == 1) {
        globalsInitTab = settingProvider.defaultTab!;
      } else {
        followInitTab = settingProvider.defaultTab!;
      }
    }

    followTabController =
        TabController(initialIndex: followInitTab, length: 3, vsync: this);
    globalsTabController =
        TabController(initialIndex: globalsInitTab, length: 3, vsync: this);
    dmTabController = TabController(length: 2, vsync: this);
  }

  @override
  Future<void> onReady(BuildContext context) async {
    if (settingProvider.lockOpen == OpenStatus.OPEN && !unlock) {
      doAuth();
    } else {
      setState(() {
        unlock = true;
      });
    }
  }

  bool unlock = false;

  @override
  Widget doBuild(BuildContext context) {
    mediaDataCache.update(context);
    var s = S.of(context);

    var _settingProvider = Provider.of<SettingProvider>(context);
    if (nostr == null) {
      return LoginRouter();
    }

    if (!unlock) {
      return Scaffold();
    }

    var _indexProvider = Provider.of<IndexProvider>(context);
    _indexProvider.setFollowTabController(followTabController);
    _indexProvider.setGlobalTabController(globalsTabController);
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
            child: Text(s.Posts),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(
              s.Posts_and_replies,
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(s.Mentions),
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
            child: Text(s.Notes),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(s.Users),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(s.Topics),
          ),
        ],
        controller: globalsTabController,
      );
    } else if (_indexProvider.currentTap == 2) {
      appBarCenter = Center(
        child: Text(
          s.Search,
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
            child: Text(s.Request),
          ),
        ],
        controller: dmTabController,
      );
    }

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

  void doAuth() {
    AuthUtil.authenticate(context, S.of(context).Please_authenticate_to_use_app)
        .then((didAuthenticate) {
      if (didAuthenticate) {
        setState(() {
          unlock = true;
        });
      } else {
        doAuth();
      }
    });
  }
}
