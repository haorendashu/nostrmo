import 'package:flutter/material.dart';

import 'events/globals_events_router.dart';
import 'tags/globals_tags_router.dart';
import 'users/globals_users_router.dart';

class GlobalsIndexRouter extends StatefulWidget {
  TabController tabController;

  GlobalsIndexRouter({required this.tabController});

  @override
  State<StatefulWidget> createState() {
    return _GlobalsIndexRouter();
  }
}

class _GlobalsIndexRouter extends State<GlobalsIndexRouter> {
  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        GlobalsEventsRouter(),
        GlobalsUsersRouter(),
        GlobalsTagsRouter(),
      ],
      controller: widget.tabController,
    );
  }
}
