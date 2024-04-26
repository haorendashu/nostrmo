import 'package:flutter/material.dart';
import 'package:nostrmo/router/filter/filter_block_component.dart';
import 'package:nostrmo/router/filter/filter_dirtyword_component.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../generated/l10n.dart';
import '../../util/platform_util.dart';
import '../../util/router_util.dart';
import '../index/index_app_bar.dart';

class FilterRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FilterRouter();
  }
}

class _FilterRouter extends State<FilterRouter>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var titleTextColor = themeData.appBarTheme.titleTextStyle!.color;
    var titleTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: titleTextColor,
    );
    Color? indicatorColor = titleTextColor;
    if (PlatformUtil.isTableMode()) {
      indicatorColor = themeData.primaryColor;
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: TabBar(
          indicatorColor: indicatorColor,
          indicatorWeight: 3,
          controller: tabController,
          tabs: [
            Container(
              height: IndexAppBar.height,
              alignment: Alignment.center,
              child: Text(
                s.Blocks,
                style: titleTextStyle,
              ),
            ),
            Container(
              height: IndexAppBar.height,
              alignment: Alignment.center,
              child: Text(
                s.Dirtywords,
                style: titleTextStyle,
              ),
            )
          ],
        ),
        actions: [
          Container(
            width: 50,
            // height: 10,
            // color: Colors.red,
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          FilterBlockComponent(),
          FilterDirtywordComponent(),
        ],
      ),
    );
  }
}
