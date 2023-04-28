import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../client/nip04/nip04.dart';
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
    var agreement = NIP04.getAgreement(nostr!.privateKey!);

    return Container(
      color: themeData.scaffoldBackgroundColor,
      child: TabBarView(
        controller: widget.tabController,
        children: [
          DMKnownListRouter(
            agreement: agreement,
          ),
          DMUnknownListRouter(
            agreement: agreement,
          ),
        ],
      ),
    );
  }
}
