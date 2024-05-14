import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:nostrmo/component/music/music_component.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/pc_router_fake.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/music_provider.dart';
import 'package:nostrmo/provider/pc_router_fake_provider.dart';
import 'package:nostrmo/router/follow_suggest/follow_suggest_router.dart';
import 'package:nostrmo/router/index/index_pc_drawer_wrapper.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:nostrmo/util/string_util.dart';
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
import 'index_tab_item_component.dart';

class IndexRouter extends StatefulWidget {
  static double PC_MAX_COLUMN_0 = 200;

  static double PC_MAX_COLUMN_1 = 550;

  Function reload;

  IndexRouter({required this.reload});

  @override
  State<StatefulWidget> createState() {
    return _IndexRouter();
  }
}

class _IndexRouter extends CustState<IndexRouter>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController followTabController;

  late TabController globalsTabController;

  late TabController dmTabController;

  @override
  void initState() {
    super.initState();
    int followInitTab = 0;
    int globalsInitTab = 0;

    WidgetsBinding.instance.addObserver(this);

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

    if (!PlatformUtil.isPC() && !PlatformUtil.isWeb()) {
      try {
        asyncInitState();
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        print("AppLifecycleState.resumed");
        nostr!.reconnect();
        break;
      case AppLifecycleState.inactive:
        print("AppLifecycleState.inactive");
        break;
      case AppLifecycleState.detached:
        print("AppLifecycleState.detached");
        break;
      case AppLifecycleState.paused:
        print("AppLifecycleState.paused");
        break;
      case AppLifecycleState.hidden:
        print("AppLifecycleState.hidden");
        break;
    }
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

    if (newUser) {
      return FollowSuggestRouter();
    }

    var _indexProvider = Provider.of<IndexProvider>(context);
    _indexProvider.setFollowTabController(followTabController);
    _indexProvider.setGlobalTabController(globalsTabController);
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    var titleTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: titleTextColor,
    );
    Color? indicatorColor = titleTextColor;
    if (PlatformUtil.isPC()) {
      indicatorColor = themeData.primaryColor;
    }

    Widget? appBarCenter;
    if (_indexProvider.currentTap == 0) {
      appBarCenter = TabBar(
        indicatorColor: indicatorColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        labelPadding: EdgeInsets.zero,
        tabs: [
          IndexTabItemComponent(
            s.Posts,
            titleTextStyle,
            omitText: "P",
          ),
          IndexTabItemComponent(
            s.Posts_and_replies,
            titleTextStyle,
            omitText: "PR",
          ),
          IndexTabItemComponent(
            s.Mentions,
            titleTextStyle,
            omitText: "M",
          ),
        ],
        controller: followTabController,
      );
    } else if (_indexProvider.currentTap == 1) {
      appBarCenter = TabBar(
        indicatorColor: indicatorColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        tabs: [
          IndexTabItemComponent(
            s.Notes,
            titleTextStyle,
            omitText: "N",
          ),
          IndexTabItemComponent(
            s.Users,
            titleTextStyle,
            omitText: "U",
          ),
          IndexTabItemComponent(
            s.Topics,
            titleTextStyle,
            omitText: "T",
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
        indicatorColor: indicatorColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        tabs: [
          IndexTabItemComponent(
            s.DMs,
            titleTextStyle,
            omitText: "DM",
          ),
          IndexTabItemComponent(
            s.Request,
            titleTextStyle,
            omitText: "R",
          ),
        ],
        controller: dmTabController,
      );
    }

    var addBtn = FloatingActionButton(
      onPressed: () {
        EditorRouter.open(context);
      },
      backgroundColor: mainColor,
      shape: const CircleBorder(),
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );

    var mainCenterWidget = MediaQuery.removePadding(
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
    );

    List<Widget> mainIndexList = [
      Column(
        children: [
          IndexAppBar(
            center: appBarCenter,
          ),
          mainCenterWidget,
        ],
      ),
      Positioned(
        bottom: Base.BASE_PADDING,
        left: 0,
        right: 0,
        child: Selector<MusicProvider, MusicInfo?>(
          builder: ((context, musicInfo, child) {
            if (musicInfo != null) {
              return MusicComponent(
                musicInfo,
                clearAble: true,
              );
            }

            return Container();
          }),
          selector: (context, _provider) {
            return _provider.musicInfo;
          },
        ),
      )
    ];
    Widget mainIndex = Stack(
      children: mainIndexList,
    );

    if (PlatformUtil.isTableMode()) {
      var maxWidth = mediaDataCache.size.width;
      double column0Width = maxWidth * 1 / 5;
      double column1Width = maxWidth * 2 / 5;
      if (column0Width > IndexRouter.PC_MAX_COLUMN_0) {
        column0Width = IndexRouter.PC_MAX_COLUMN_0;
      }
      if (column1Width > IndexRouter.PC_MAX_COLUMN_1) {
        column1Width = IndexRouter.PC_MAX_COLUMN_1;
      }

      return Scaffold(
        // floatingActionButton: addBtn,
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: Row(children: [
          IndexPcDrawerWrapper(
            fixWidth: column0Width,
          ),
          Container(
            width: column1Width,
            margin: EdgeInsets.only(
              // left: 1,
              right: 1,
            ),
            child: mainIndex,
          ),
          Expanded(
            child: Container(
              child: Selector<PcRouterFakeProvider, List<RouterFakeInfo>>(
                builder: (context, infos, child) {
                  if (infos.isEmpty) {
                    return Container(
                      child: Center(
                        child: Text(s.There_should_be_an_universe_here),
                      ),
                    );
                  }

                  List<Widget> pages = [];
                  for (var info in infos) {
                    if (StringUtil.isNotBlank(info.routerPath) &&
                        routes[info.routerPath] != null) {
                      var builder = routes[info.routerPath];
                      if (builder != null) {
                        pages.add(PcRouterFake(
                          info: info,
                          child: builder(context),
                        ));
                      }
                    } else if (info.buildContent != null) {
                      pages.add(PcRouterFake(
                        info: info,
                        child: info.buildContent!(context),
                      ));
                    }
                  }

                  return IndexedStack(
                    index: pages.length - 1,
                    children: pages,
                  );
                },
                selector: (context, _provider) {
                  return _provider.routerFakeInfos;
                },
                shouldRebuild: (previous, next) {
                  if (previous != next) {
                    return true;
                  }
                  return false;
                },
              ),
            ),
          )
        ]),
      );
    } else {
      return Scaffold(
        body: mainIndex,
        floatingActionButton: addBtn,
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterDocked,
        drawer: Drawer(
          child: IndexDrawerContnetComponnent(
            smallMode: false,
          ),
        ),
        bottomNavigationBar: IndexBottomBar(),
      );
    }
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

  StreamSubscription? _purchaseUpdatedSubscription;

  void asyncInitState() async {
    await FlutterInappPurchase.instance.initialize();
    _purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((productItem) async {
      if (productItem == null) {
        return;
      }

      try {
        if (Platform.isAndroid) {
          await FlutterInappPurchase.instance.finishTransaction(productItem);
        } else if (Platform.isIOS) {
          await FlutterInappPurchase.instance
              .finishTransactionIOS(productItem.transactionId!);
        }
      } catch (e) {
        print(e);
      }
      print('purchase-updated: $productItem');
      BotToast.showText(text: "Thanks yours coffee!");
    });
  }

  @override
  void dispose() async {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (!PlatformUtil.isPC() && !PlatformUtil.isWeb()) {
      if (_purchaseUpdatedSubscription != null) {
        _purchaseUpdatedSubscription!.cancel();
        _purchaseUpdatedSubscription = null;
      }
      await FlutterInappPurchase.instance.finalize();
    }
  }
}
