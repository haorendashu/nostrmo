import 'dart:convert';
import 'dart:math';

import 'package:dynamic_height_grid_view/dynamic_height_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/user/simple_metadata_component.dart';

import '../../client/event.dart';
import '../../client/event_kind.dart';
import '../../client/filter.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/dio_util.dart';
import '../../util/platform_util.dart';
import '../../util/string_util.dart';

class FollowSuggestRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FollowSuggestRouter();
  }
}

class _FollowSuggestRouter extends CustState<FollowSuggestRouter> {
  @override
  Widget doBuild(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;

    int crossAxisCount = 1;
    if (PlatformUtil.isTableMode()) {
      crossAxisCount = 2;
    }

    List<Widget> mainList = [];
    mainList.add(Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: 18,
      ),
      child: Text(
        s.Popular_Users,
        style: TextStyle(
          fontSize: themeData.textTheme.bodyLarge!.fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    List<Widget> userWidgetList = [];
    for (var pubkey in pubkeys) {
      userWidgetList.add(SimpleMetadataComponent(
        pubkey: pubkey,
      ));
    }
    mainList.add(Expanded(
      child: DynamicHeightGridView(
        shrinkWrap: true,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: Base.BASE_PADDING,
        crossAxisSpacing: Base.BASE_PADDING,
        itemCount: pubkeys.length,
        builder: (context, index) {
          var pubkey = pubkeys[index];
          return SimpleMetadataComponent(
            pubkey: pubkey,
            showFollow: true,
          );
        },
      ),
    ));

    mainList.add(Container(
      width: double.maxFinite,
      alignment: Alignment.centerRight,
      margin: EdgeInsets.only(
        top: Base.BASE_PADDING * 2,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: goToIndex,
        child: Text(
          "Go!",
          style: TextStyle(
            color: mainColor,
            decoration: TextDecoration.underline,
            decorationColor: mainColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ));

    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(
          Base.BASE_PADDING * 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: mainList,
        ),
      ),
    );
  }

  void goToIndex() {
    newUser = false;
    settingProvider.notifyListeners();
  }

  @override
  Future<void> onReady(BuildContext context) async {
    loadData();
  }

  List<String> pubkeys = [];

  Future<void> loadData() async {
    var str = await DioUtil.getStr(Base.INDEXS_CONTACTS);
    if (StringUtil.isNotBlank(str)) {
      pubkeys.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        pubkeys.add(itf as String);
      }

      // Disorder
      for (var i = 1; i < pubkeys.length; i++) {
        var j = getRandomInt(0, i);
        var t = pubkeys[i];
        pubkeys[i] = pubkeys[j];
        pubkeys[j] = t;
      }

      // query the pre 20 pubkeys
      List<Map<String, dynamic>> filters = [];
      for (var i = 0; i < pubkeys.length && i < 10; i++) {
        var pubkey = pubkeys[i];
        var filter = Filter(kinds: [
          EventKind.METADATA,
        ], authors: [
          pubkey
        ]);
        filters.add(filter.toJson());
      }
      if (filters.isNotEmpty) {
        nostr!.addInitQuery(filters, onEvent);
      }
      filters = [];
      for (var i = 10; i < pubkeys.length && i < 20; i++) {
        var pubkey = pubkeys[i];
        var filter = Filter(kinds: [
          EventKind.METADATA,
        ], authors: [
          pubkey
        ]);
        filters.add(filter.toJson());
      }
      if (filters.isNotEmpty) {
        nostr!.addInitQuery(filters, onEvent);
      }

      setState(() {});
    }
  }

  void onEvent(Event e) {
    metadataProvider.onEvent(e);
  }

  int getRandomInt(int min, int max) {
    final _random = new Random();
    return _random.nextInt((max - min).floor()) + min;
  }
}
