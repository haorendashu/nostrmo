import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../client/nip04/nip04.dart';
import '../../main.dart';
import '../../provider/dm_provider.dart';
import 'dm_session_list_item_component.dart';

class DMRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _DMRouter();
  }
}

class _DMRouter extends State<DMRouter> {
  @override
  Widget build(BuildContext context) {
    var _dmProvider = Provider.of<DMProvider>(context);
    var dmSessions = _dmProvider.list();

    if (dmSessions.isEmpty) {
      return Container(
        child: Center(
          child: Text("DMs"),
        ),
      );
    }

    var agreement = NIP04.getAgreement(nostr!.privateKey);

    return Container(
      child: ListView.builder(
        itemBuilder: (context, index) {
          if (index >= dmSessions.length) {
            return null;
          }

          var dmSession = dmSessions[index];
          return DMSessionListItemComponent(
            dmSession: dmSession,
            agreement: agreement,
          );
        },
        itemCount: dmSessions.length,
      ),
    );
  }
}
