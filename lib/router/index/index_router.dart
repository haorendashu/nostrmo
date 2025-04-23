import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/add_btn_wrapper_component.dart';
import 'package:nostrmo/component/music/music_component.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/pc_router_fake.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/music_provider.dart';
import 'package:nostrmo/provider/pc_router_fake_provider.dart';
import 'package:nostrmo/router/follow_suggest/follow_suggest_router.dart';
import 'package:nostrmo/router/index/index_pc_drawer_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../component/user/user_pic_component.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/index_provider.dart';
import '../../provider/relay_provider.dart';
import '../../provider/setting_provider.dart';
import '../../util/auth_util.dart';
import '../../util/router_util.dart';
import '../../util/table_mode_util.dart';
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

  IndexRouter({super.key, required this.reload});

  @override
  State<StatefulWidget> createState() {
    return _IndexRouter();
  }
}

class _IndexRouter extends CustState<IndexRouter>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        TrayListener,
        WindowListener {
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
    dmTabController = TabController(length: 3, vsync: this);

    if (!PlatformUtil.isPC() && !PlatformUtil.isWeb()) {
      try {
        asyncInitState();
      } catch (e) {
        print(e);
      }
    }

    if (PlatformUtil.isPC()) {
      trayManager.addListener(this);
      windowManager.addListener(this);
      _initTray();
    }
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

    if (PlatformUtil.isPC()) {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        print("AppLifecycleState.resumed");
        if (nostr != null) {
          nostr!.reconnect();
        }
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

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  Future<void> onTrayIconMouseDown() async {
    if (!PlatformUtil.isMacOS()) {
      if (await windowManager.isVisible()) {
        windowManager.hide();
      } else {
        await windowManager.show();
        await windowManager.focus();
      }
    }
  }

  @override
  void onWindowMinimize() {
    if (PlatformUtil.isWindows() || PlatformUtil.isMacOS()) {
      windowManager.hide();
    }
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'exit_app') {
      windowManager.close();
      return;
    }

    await windowManager.show();
    await windowManager.focus();

    if (menuItem.key == 'add_note') {
      AddBtnWrapperComponent.addNote(context);
    } else if (menuItem.key == 'add_article') {
      AddBtnWrapperComponent.addArticle(context);
    } else if (menuItem.key == 'add_media') {
      AddBtnWrapperComponent.addMedia(context);
    } else if (menuItem.key == 'add_poll') {
      AddBtnWrapperComponent.addPoll(context);
    } else if (menuItem.key == 'add_zap_goal') {
      AddBtnWrapperComponent.addZapGoal(context);
    }
  }

  Future<void> _initTray() async {
    await trayManager.setIcon(
      PlatformUtil.isWindows()
          ? "assets/imgs/logo/logo.ico"
          : "assets/imgs/logo/logo512.png",
    );
    if (PlatformUtil.isMacOS() || PlatformUtil.isWindows()) {
      await trayManager.setToolTip("Nostrmo");
    }
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'add_note',
          label: "${s.Add} ${s.Note}",
        ),
        MenuItem(
          key: 'add_article',
          label: "${s.Add} ${s.Article}",
        ),
        MenuItem(
          key: 'add_media',
          label: "${s.Add} ${s.Media}",
        ),
        MenuItem(
          key: 'add_poll',
          label: "${s.Add} ${s.Poll}",
        ),
        MenuItem(
          key: 'add_zap_goal',
          label: "${s.Add} ${s.Zap_Goal}",
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: s.Exit_App,
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
    print("trayManager.setContextMenu");
  }

  bool unlock = false;

  late S s;

  @override
  Widget doBuild(BuildContext context) {
    mediaDataCache.update(context);

    s = S.of(context);

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
    Color? indicatorColor = themeData.primaryColor;

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
          IndexTabItemComponent(
            s.Groups,
            titleTextStyle,
            omitText: "G",
          ),
        ],
        controller: dmTabController,
      );
    }

    var indexAppBar = AppBar(
      leading: TableModeUtil.isTableMode()
          ? null
          : GestureDetector(
              onTap: () {
                if (mobileScaffoldKey.currentState != null) {
                  mobileScaffoldKey.currentState!.openDrawer();
                }
              },
              child: Container(
                margin: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                alignment: Alignment.center,
                child: UserPicComponent(
                  pubkey: nostr!.publicKey,
                  width: picHeight,
                ),
              ),
            ),
      title: appBarCenter,
      actions: [
        GestureDetector(
          onTap: () {
            RouterUtil.router(context, RouterPath.RELAYS);
          },
          child: Container(
            margin: const EdgeInsets.only(right: Base.BASE_PADDING),
            child: Selector<RelayProvider, String>(
                builder: (context, relayNum, child) {
              return Text(
                relayNum,
                style: TextStyle(color: titleTextColor),
              );
            }, selector: (context, _provider) {
              return _provider.relayNumStr();
            }),
          ),
        ),
      ],
    );

    var mainCenterWidget = IndexedStack(
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
    );

    var musicWidget = Selector<MusicProvider, MusicInfo?>(
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
    );

    List<Widget> mainIndexList = [
      mainCenterWidget,
      Positioned(
        bottom: Base.BASE_PADDING,
        left: 0,
        right: 0,
        child: musicWidget,
      ),
    ];
    Widget mainIndex = Stack(
      children: mainIndexList,
    );

    if (TableModeUtil.isTableMode()) {
      var maxWidth = mediaDataCache.size.width;
      double column0Width = maxWidth * 1 / 5;
      double column1Width = maxWidth * 2 / 5;
      if (column0Width > IndexRouter.PC_MAX_COLUMN_0) {
        column0Width = IndexRouter.PC_MAX_COLUMN_0;
      }
      if (column1Width > IndexRouter.PC_MAX_COLUMN_1) {
        column1Width = IndexRouter.PC_MAX_COLUMN_1;
      }

      var mainScaffold = Scaffold(
        body: Row(children: [
          IndexPcDrawerWrapper(
            fixWidth: column0Width,
          ),
          Container(
            width: column1Width,
            margin: const EdgeInsets.only(
              right: 1,
            ),
            child: Column(
              children: [
                indexAppBar,
                Expanded(child: mainIndex),
              ],
            ),
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

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (pcRouterFakeProvider.routerFakeInfos.isNotEmpty) {
            pcRouterFakeProvider.removeLast();
          }
        },
        child: mainScaffold,
      );
    } else {
      return Scaffold(
        key: mobileScaffoldKey,
        appBar: indexAppBar,
        body: mainIndex,
        drawer: Drawer(
          child: IndexDrawerContentComponnent(
            smallMode: false,
          ),
        ),
        bottomNavigationBar: IndexBottomBar(),
      );
    }
  }

  GlobalKey<ScaffoldState> mobileScaffoldKey = GlobalKey();

  double picHeight = 30;

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
        if (PlatformUtil.isAndroid()) {
          await FlutterInappPurchase.instance.finishTransaction(productItem);
        } else if (PlatformUtil.isIOS()) {
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
}
