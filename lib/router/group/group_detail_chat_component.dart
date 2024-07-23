import 'package:flutter/material.dart';

import '../../client/nip29/group_identifier.dart';
import '../../component/keep_alive_cust_state.dart';

class GroupDetailChatComponent extends StatefulWidget {
  GroupIdentifier groupIdentifier;

  GroupDetailChatComponent(this.groupIdentifier);

  @override
  State<StatefulWidget> createState() {
    return _GroupDetailChatComponent();
  }
}

class _GroupDetailChatComponent
    extends KeepAliveCustState<GroupDetailChatComponent> {
  @override
  Widget doBuild(BuildContext context) {
    return Container();
  }

  @override
  Future<void> onReady(BuildContext context) async {}
}
