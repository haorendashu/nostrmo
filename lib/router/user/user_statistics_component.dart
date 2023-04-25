import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:provider/provider.dart';

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
  int relaysNum = 0;
  int? zapNum;

  bool isLocal = false;

  String? pubkey;

  @override
  Widget doBuild(BuildContext context) {
    var s = S.of(context);
    if (pubkey != null && pubkey != widget.pubkey) {
      // arg changed! reset
      contactListEvent = null;
      contactList = null;
      relaysEvent = null;
      relaysTags = null;
      zapEventBox = null;

      length = 0;
      relaysNum = 0;
      zapNum;
      doQuery();
    }
    pubkey = widget.pubkey;

    isLocal = widget.pubkey == nostr!.publicKey;

    List<Widget> list = [];

    if (isLocal) {
      list.add(
          Selector<ContactListProvider, int>(builder: (context, num, child) {
        return UserStatisticsItemComponent(
            num: num, name: s.Following, onTap: onFollowingTap);
      }, selector: (context, _provider) {
        return _provider.total();
      }));
    } else {
      if (contactList != null) {
        length = contactList!.list().length;
      }
      list.add(UserStatisticsItemComponent(
          num: length, name: s.Following, onTap: onFollowingTap));
    }

    if (isLocal) {
      list.add(Selector<RelayProvider, int>(builder: (context, num, child) {
        return UserStatisticsItemComponent(
            num: num, name: s.Relays, onTap: onRelaysTap);
      }, selector: (context, _provider) {
        return _provider.total();
      }));
    } else {
      if (relaysTags != null) {
        relaysNum = relaysTags!.length;
      }
      list.add(UserStatisticsItemComponent(
          num: relaysNum, name: s.Relays, onTap: onRelaysTap));
    }

    list.add(UserStatisticsItemComponent(
      num: zapNum,
      name: "Zap",
      onTap: onZapTap,
      formatNum: true,
    ));

    return Container(
      // color: Colors.red,
      height: 18,
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }

  String queryId = "";

  String queryId2 = "";

  @override
  Future<void> onReady(BuildContext context) async {
    if (!isLocal) {
      doQuery();
    }
  }

  void doQuery() {
    {
      queryId = StringUtil.rndNameStr(16);
      var filter = Filter(
          authors: [widget.pubkey],
          limit: 1,
          kinds: [kind.EventKind.CONTACT_LIST]);
      nostr!.pool.query([filter.toJson()], (event) {
        if (((contactListEvent != null &&
                    event.createdAt > contactListEvent!.createdAt) ||
                contactListEvent == null) &&
            !_disposed) {
          setState(() {
            contactListEvent = event;
            contactList = CustContactList.fromJson(event.tags);
          });
        }
      }, queryId);
    }

    {
      queryId2 = StringUtil.rndNameStr(16);
      var filter = Filter(
          authors: [widget.pubkey],
          limit: 1,
          kinds: [kind.EventKind.RELAY_LIST_METADATA]);
      nostr!.pool.query([filter.toJson()], (event) {
        if (((relaysEvent != null &&
                    event.createdAt > relaysEvent!.createdAt) ||
                relaysEvent == null) &&
            !_disposed) {
          setState(() {
            relaysEvent = event;
            relaysTags = event.tags;
          });
        }
      }, queryId2);
    }
  }

  onFollowingTap() {
    if (contactList != null) {
      RouterUtil.router(context, RouterPath.USER_CONTACT_LIST, contactList);
    } else if (isLocal) {
      var cl = contactListProvider.contactList;
      if (cl != null) {
        RouterUtil.router(context, RouterPath.USER_CONTACT_LIST, cl);
      }
    }
  }

  onFollowedTap() {
    print("onFollowedTap");
  }

  onRelaysTap() {
    if (relaysTags != null && relaysTags!.isNotEmpty) {
      RouterUtil.router(context, RouterPath.USER_RELAYS, relaysTags);
    } else if (isLocal) {
      RouterUtil.router(context, RouterPath.RELAYS);
    }
  }

  String zapSubscribeId = "";

  onZapTap() {
    if (zapEventBox == null) {
      zapEventBox = EventMemBox(sortAfterAdd: false);
      // pull zap event
      var filter = Filter(kinds: [kind.EventKind.ZAP], p: [widget.pubkey]);
      zapSubscribeId = StringUtil.rndNameStr(12);
      // print(filter);
      nostr!.pool.query([filter.toJson()], onZapEvent, zapSubscribeId);

      zapNum = 0;
    } else {
      // Router to vist list
      zapEventBox!.sort();
      var list = zapEventBox!.all();
      RouterUtil.router(context, RouterPath.USER_ZAP_LIST, list);
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

    _disposed = true;
    checkAndUnsubscribe(queryId);
    checkAndUnsubscribe(queryId2);
    checkAndUnsubscribe(zapSubscribeId);
  }

  void checkAndUnsubscribe(String queryId) {
    if (StringUtil.isNotBlank(queryId)) {
      try {
        nostr!.pool.unsubscribe(queryId);
      } catch (e) {}
    }
  }

  bool _disposed = false;
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
