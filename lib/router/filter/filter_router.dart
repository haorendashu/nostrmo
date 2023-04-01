import 'package:flutter/material.dart';
import 'package:nostrmo/router/filter/filter_block_component.dart';
import 'package:nostrmo/router/filter/filter_dirtyword_component.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: TabBar(
          controller: tabController,
          tabs: [
            Container(
              height: IndexAppBar.height,
              alignment: Alignment.center,
              child: Text("Blocks"),
            ),
            Container(
              height: IndexAppBar.height,
              alignment: Alignment.center,
              child: Text(
                "Dirtywords",
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
