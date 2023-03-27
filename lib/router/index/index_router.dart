import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/cust_nostr.dart';
import 'package:nostrmo/client/cust_relay.dart';
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:nostrmo/router/dm/dm_router.dart';
import 'package:nostrmo/router/follow/follow_router.dart';
import 'package:nostrmo/router/notice/notice_router.dart';
import 'package:nostrmo/router/search/search_router.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:provider/provider.dart';

import '../../component/user_pic_component.dart';
import '../../data/metadata.dart';
import '../../data/relay_status.dart';
import '../../provider/index_provider.dart';
import '../../provider/metadata_provider.dart';
import '../follow/follow_index_router.dart';
import '../follow/mention_me_router.dart';
import '../login/login_router.dart';
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
  // ECPrivateKey getPrivateKey(String privateKey) {
  //   var d0 = BigInt.parse(privateKey, radix: 16);
  //   return ECPrivateKey(d0, secp256k1);
  // }

  // var secp256k1 = ECDomainParameters("secp256k1");

  // String keyToString(BigInt d0) {
  //   ECPoint P = (secp256k1.G * d0)!;
  //   return P.x!.toBigInteger()!.toRadixString(16).padLeft(64, "0");
  // }

  late TabController followTabController;

  late TabController dmTabController;

  @override
  void initState() {
    super.initState();
    followTabController = TabController(length: 2, vsync: this);
    dmTabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
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
            child: Text("Following"),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text("Mentioned"),
          ),
        ],
        controller: followTabController,
      );
    } else if (_indexProvider.currentTap == 1) {
      appBarCenter = Center(
        child: Text(
          "Search",
          style: titleTextStyle,
        ),
      );
    } else if (_indexProvider.currentTap == 2) {
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
    } else if (_indexProvider.currentTap == 3) {
      appBarCenter = Center(
        child: Text(
          "Notice",
          style: titleTextStyle,
        ),
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
                SearchRouter(),
                DMRouter(
                  tabController: dmTabController,
                ),
                NoticeRouter(),
              ],
            )),
          ),
          IndexBottomBar(),
        ],
      ),
      drawer: Drawer(
        child: IndexDrawerContnetComponnent(),
      ),
    );
  }
}
