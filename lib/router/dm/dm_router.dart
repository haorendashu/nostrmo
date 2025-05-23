import 'package:flutter/material.dart';
import 'package:nostrmo/router/group/group_list_rotuer.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../provider/dm_provider.dart';
import 'dm_known_list_router.dart';
import 'dm_session_list_item_component.dart';
import 'dm_unknown_list_router.dart';

class DMRouter extends StatefulWidget {
  TabController tabController;

  DMRouter({required this.tabController});

  @override
  State<StatefulWidget> createState() {
    return _DMRouter();
  }
}

class _DMRouter extends State<DMRouter> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    return Container(
      color: themeData.scaffoldBackgroundColor,
      child: TabBarView(
        controller: widget.tabController,
        children: [
          DMKnownListRouter(),
          DMUnknownListRouter(),
          GroupListRouter(),
        ],
      ),
    );
  }
}
