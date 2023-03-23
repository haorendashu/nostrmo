import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/zap_num_util.dart';

import '../../client/event_kind.dart' as kind;
import '../../client/cust_contact_list.dart';
import '../../client/event_kind.dart' as kind;
import '../../client/filter.dart';
import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../data/event_mem_box.dart';
import '../../main.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';

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

  EventMemBox? zapEventBox;

  int length = 0;
  int? followed;
  int relaysNum = 0;
  int? zapNum;

  @override
  Widget doBuild(BuildContext context) {
    if (contactList != null) {
      length = contactList!.list().length;
      // List<String> relayList = [];
      // for (var contact in contactList!.list()) {
      //   if (StringUtil.isNotBlank(contact.url)) {
      //     relayList.add(contact.url);
      //   }
      // }
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
          UserStatisticsItemComponent(
              num: zapNum, name: "Zap", onTap: onZapTap),
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
    if (contactList != null) {
      RouterUtil.router(context, RouterPath.USER_CONTACT_LIST, contactList);
    }
  }

  onFollowedTap() {
    print("onFollowedTap");
  }

  onRelaysTap() {
    print("onRelaysTap");
  }

  String zapSubscribeId = StringUtil.rndNameStr(10);

  onZapTap() {
    if (zapEventBox == null) {
      zapEventBox = EventMemBox(sortAfterAdd: false);
      // pull zap event
      var filter = Filter(kinds: [kind.EventKind.ZAP], p: [widget.pubkey]);
      print(filter);
      nostr!.pool.query([filter.toJson()], onZapEvent, zapSubscribeId);

      zapNum = 0;
    } else {
      // Router to vist list
    }
  }

  onZapEvent(Event event) {
    print(event.toJson());
    if (event.kind == kind.EventKind.ZAP && zapEventBox!.add(event)) {
      setState(() {
        zapNum = zapNum! + ZapNumUtil.getNumFromZapEvent(event);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    try {
      nostr!.pool.unsubscribe(zapSubscribeId);
    } catch (e) {}
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
      behavior: HitTestBehavior.translucent,
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
