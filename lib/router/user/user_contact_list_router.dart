import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip02/contact_list.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';
import 'user_contact_list_component.dart';

class UserContactListRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _UserContactListRouter();
  }
}

class _UserContactListRouter extends State<UserContactListRouter> {
  ContactList? contactList;

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);

    if (contactList == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        contactList = arg as ContactList;
      }
    }
    if (contactList == null) {
      RouterUtil.back(context);
      return Container();
    }
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          s.Following,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: UserContactListComponent(contactList: contactList!),
    );
  }
}
