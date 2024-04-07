import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/placeholder/user_relay_placeholder.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/main.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/relay_status.dart';
import '../../provider/relay_provider.dart';
import '../../util/dio_util.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';
import '../user/user_relays_router.dart';

class RelayhubRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RelayhubRouter();
  }
}

class _RelayhubRouter extends CustState<RelayhubRouter> {
  List<String> addrs = [];

  @override
  Widget doBuild(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var color = themeData.textTheme.bodyLarge!.color;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    // List<Widget> list = [];
    // for (var addr in addrs) {
    //   list.add(ContentRelayComponent(addr));
    // }
    Widget mainWidget;
    if (addrs.isNotEmpty) {
      mainWidget = ListView.builder(
        itemBuilder: (context, index) {
          var relayAddr = addrs[index];
          return Selector<RelayProvider, RelayStatus?>(
              builder: (context, relayStatus, child) {
            return RelayMetadataComponent(
              addr: relayAddr,
              addAble: relayStatus == null,
            );
          }, selector: (context, _provider) {
            return _provider.getRelayStatus(relayAddr);
          });
        },
        itemCount: addrs.length,
      );
    } else {
      mainWidget = ListView.builder(
        itemBuilder: (context, index) {
          return UserRelayPlaceholder();
        },
        itemCount: 10,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: themeData.appBarTheme.titleTextStyle!.color,
          ),
        ),
        title: Text(
          "Relayhub",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: testAllSpeed,
            child: Container(
              padding: EdgeInsets.only(right: Base.BASE_PADDING),
              child: Icon(
                Icons.speed,
                color: themeData.appBarTheme.titleTextStyle!.color,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.only(
          top: Base.BASE_PADDING,
        ),
        child: mainWidget,
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    var str = await DioUtil.getStr(Base.INDEXS_RELAYS);
    // print(str);
    if (StringUtil.isNotBlank(str)) {
      addrs.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        addrs.add(itf as String);
      }
    }

    setState(() {});
  }

  Future<void> testAllSpeed() async {
    for (var addr in addrs) {
      await urlSpeedProvider.testSpeed(addr);
    }
  }
}
