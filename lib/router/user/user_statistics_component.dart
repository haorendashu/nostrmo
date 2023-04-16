import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';

import '../../client/event_kind.dart' as kind;
import '../../client/cust_contact_list.dart';
import '../../client/filter.dart';
import '../../client/zap_num_util.dart';
import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../data/event_mem_box.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/number_format_util.dart';
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
  Event? contactListEvent;

  CustContactList? contactList;

  Event? relaysEvent;

  List<dynamic>? relaysTags;

  EventMemBox? zapEventBox;

  int length = 0;
  int? followed;
  int relaysNum = 0;
  int? zapNum;

  @override
  Widget doBuild(BuildContext context) {
    var s = S.of(context);
    if (contactList != null) {
      length = contactList!.list().length;
    }
    if (relaysTags != null) {
      relaysNum = relaysTags!.length;
    }

    List<Widget> list = [];

    return Container(
      // color: Colors.red,
      height: 18,
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING),
      child: Row(
        children: [
          UserStatisticsItemComponent(
              num: length, name: s.Following, onTap: onFollowingTap),
          // UserStatisticsItemComponent(
          //     num: followed, name: "Followed", onTap: onFollowedTap),
          UserStatisticsItemComponent(
              num: relaysNum, name: s.Relays, onTap: onRelaysTap),
          UserStatisticsItemComponent(
            num: zapNum,
            name: "Zap",
            onTap: onZapTap,
            formatNum: true,
          ),
        ],
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    {
      var filter = Filter(
          authors: [widget.pubkey],
          limit: 1,
          kinds: [kind.EventKind.CONTACT_LIST]);
      nostr!.pool.query([filter.toJson()], (event) {
        if ((contactListEvent != null &&
                event.createdAt > contactListEvent!.createdAt) ||
            contactListEvent == null) {
          setState(() {
            contactListEvent = event;
            contactList = CustContactList.fromJson(event.tags);
          });
        }
      });
    }

    {
      var filter = Filter(
          authors: [widget.pubkey],
          limit: 1,
          kinds: [kind.EventKind.RELAY_LIST_METADATA]);
      nostr!.pool.query([filter.toJson()], (event) {
        if ((relaysEvent != null && event.createdAt > relaysEvent!.createdAt) ||
            relaysEvent == null) {
          setState(() {
            relaysEvent = event;
            relaysTags = event.tags;
          });
        }
      });
    }
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
    if (relaysTags != null && relaysTags!.isNotEmpty) {
      RouterUtil.router(context, RouterPath.USER_RELAYS, relaysTags);
    }
  }

  String zapSubscribeId = StringUtil.rndNameStr(10);

  onZapTap() {
    if (zapEventBox == null) {
      zapEventBox = EventMemBox(sortAfterAdd: false);
      // pull zap event
      var filter = Filter(kinds: [kind.EventKind.ZAP], p: [widget.pubkey]);
      // print(filter);
      nostr!.pool.query([filter.toJson()], onZapEvent, zapSubscribeId);

      zapNum = 0;
    } else {
      // Router to vist list
    }
  }

  onZapEvent(Event event) {
    // print(event.toJson());
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

  bool formatNum;

  UserStatisticsItemComponent({
    required this.num,
    required this.name,
    required this.onTap,
    this.formatNum = false,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var fontSize = themeData.textTheme.bodySmall!.fontSize;

    List<Widget> list = [];
    if (num != null) {
      var numStr = num.toString();
      if (formatNum) {
        numStr = NumberFormatUtil.format(num!);
      }

      list.add(Text(
        numStr,
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
