import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/string_util.dart';

import '../../client/cust_contact_list.dart';
import '../../client/event_kind.dart' as kind;
import '../../client/filter.dart';
import '../../component/cust_state.dart';
import '../../main.dart';

class UserStatisticsComponent extends StatefulWidget {
  String pubkey;

  UserStatisticsComponent({required this.pubkey});

  @override
  State<StatefulWidget> createState() {
    return _UserStatisticsComponent();
  }
}

class _UserStatisticsComponent extends CustState<UserStatisticsComponent> {
  CustContactList? contactList;

  @override
  Widget doBuild(BuildContext context) {
    int length = 0;
    int? followed;
    int relaysNum = 0;
    if (contactList != null) {
      length = contactList!.list().length;
      List<String> relayList = [];
      for (var contact in contactList!.list()) {
        if (StringUtil.isNotBlank(contact.url)) {
          relayList.add(contact.url);
        }
      }
    }

    List<Widget> list = [];

    return Container(
      // color: Colors.red,
      height: 18,
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING),
      child: Row(
        children: [
          UserStatisticsItemComponent(
              num: length, name: "Following", onTap: onFollowingTap),
          UserStatisticsItemComponent(
              num: followed, name: "Followed", onTap: onFollowedTap),
          UserStatisticsItemComponent(
              num: relaysNum, name: "Relays", onTap: onRelaysTap),
        ],
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    var filter = Filter(
        authors: [widget.pubkey],
        limit: 1,
        kinds: [kind.EventKind.CONTACT_LIST]);
    nostr!.pool.query([filter.toJson()], (event) {
      setState(() {
        contactList = CustContactList.fromJson(event.tags);
      });
    });
  }

  onFollowingTap() {
    print("onFollowingTap");
  }

  onFollowedTap() {
    print("onFollowedTap");
  }

  onRelaysTap() {
    print("onRelaysTap");
  }
}

class UserStatisticsItemComponent extends StatelessWidget {
  int? num;

  String name;

  Function onTap;

  UserStatisticsItemComponent({
    required this.num,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var fontSize = themeData.textTheme.bodySmall!.fontSize;

    List<Widget> list = [];
    if (num != null) {
      list.add(Text(
        num.toString(),
        style: TextStyle(
          fontSize: fontSize,
        ),
      ));
    } else {
      list.add(Icon(
        Icons.download,
        size: 14,
      ));
    }
    list.add(Container(
      margin: EdgeInsets.only(left: 4),
      child: Text(
        name,
        style: TextStyle(
          color: hintColor,
          fontSize: fontSize,
        ),
      ),
    ));

    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        margin: EdgeInsets.only(left: Base.BASE_PADDING),
        child: Row(children: list),
      ),
    );
  }
}
