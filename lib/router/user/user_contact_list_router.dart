import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:provider/provider.dart';

import '../../client/cust_contact_list.dart';
import '../../component/user/metadata_component.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import '../../util/router_util.dart';

class UserContactListRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _UserContactListRouter();
  }
}

class _UserContactListRouter extends State<UserContactListRouter> {
  CustContactList? contactList;

  List<Contact> list = [];

  @override
  Widget build(BuildContext context) {
    if (contactList == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        contactList = arg as CustContactList;
        list = contactList!.list().toList();
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
        title: Text(
          "Following",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          var contact = list[index];
          return Container(
            margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
            child: Selector<MetadataProvider, Metadata?>(
              builder: (context, metadata, child) {
                return GestureDetector(
                  onTap: () {
                    RouterUtil.router(
                        context, RouterPath.USER, contact.publicKey);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: MetadataComponent(
                    pubKey: contact.publicKey,
                    metadata: metadata,
                    jumpable: true,
                  ),
                );
              },
              selector: (context, _provider) {
                return _provider.getMetadata(contact.publicKey);
              },
            ),
          );
        },
        itemCount: list.length,
      ),
    );
  }
}
