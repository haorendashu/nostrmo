import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip02/contact_list.dart';
import 'package:nostr_sdk/zap/zap_info_util.dart';
import 'package:nostrmo/component/enum_selector_component.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:provider/provider.dart';

import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/number_format_util.dart';
import '../../util/router_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';

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

  ContactList? contactList;

  Event? relaysEvent;

  List<dynamic>? relaysTags;

  EventMemBox? zapEventBox;

  // followedMap
  Map<String, Event>? followedMap;

  int length = 0;
  int relaysNum = 0;
  int followedTagsLength = 0;
  int followedCommunitiesLength = 0;
  int? zapNum;
  int? followedNum;

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
      followedMap = null;

      length = 0;
      relaysNum = 0;
      followedTagsLength = 0;
      followedCommunitiesLength = 0;
      zapNum = null;
      followedNum = null;
      doQuery();
    }
    pubkey = widget.pubkey;
    isLocal = widget.pubkey == nostr!.publicKey;

    if (isLocal) {
      var _provider = Provider.of<ContactListProvider>(context);
      List<Widget> list = [];
      list.add(UserStatisticsItemComponent(
        num: _provider.total(),
        name: s.Following,
        onTap: onFollowingTap,
        onLongPressStart: onLongPressStart,
        onLongPressEnd: onLongPressEnd,
      ));

      list.add(UserStatisticsItemComponent(
          num: _provider.followSetEventMap.length,
          name: s.Follow_set,
          onTap: () {
            RouterUtil.router(context, RouterPath.FOLLOW_SET_LIST);
          }));

      list.add(Selector<ListProvider, int>(builder: (context, num, child) {
        return UserStatisticsItemComponent(
            num: num,
            name: s.Groups,
            onTap: () {
              RouterUtil.router(context, RouterPath.GROUP_LIST);
            });
      }, selector: (context, _provider) {
        return _provider.groupIdentifiers.length;
      }));

      list.add(Selector<RelayProvider, int>(builder: (context, num, child) {
        return UserStatisticsItemComponent(
            num: num, name: s.Relays, onTap: onRelaysTap);
      }, selector: (context, _provider) {
        return _provider.total();
      }));

      list.add(UserStatisticsItemComponent(
        num: followedNum,
        name: s.Followed,
        onTap: onFollowedTap,
        formatNum: true,
      ));

      list.add(UserStatisticsItemComponent(
        num: zapNum,
        name: "Zap",
        onTap: onZapTap,
        formatNum: true,
      ));

      list.add(UserStatisticsItemComponent(
        num: _provider.totalFollowedTags(),
        name: s.Followed_Tags,
        onTap: onFollowedTagsTap,
      ));

      list.add(UserStatisticsItemComponent(
        num: _provider.totalfollowedCommunities(),
        name: s.Followed_Communities,
        onTap: onFollowedCommunitiesTap,
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
    } else {
      var _provider = Provider.of<MetadataProvider>(context);
      contactList = _provider.getContactList(pubkey!);

      List<Widget> list = [];

      if (contactList != null) {
        length = contactList!.list().length;
      }
      list.add(UserStatisticsItemComponent(
          num: length, name: s.Following, onTap: onFollowingTap));

      if (relaysTags != null) {
        relaysNum = relaysTags!.length;
      }
      list.add(UserStatisticsItemComponent(
          num: relaysNum, name: s.Relays, onTap: onRelaysTap));

      list.add(UserStatisticsItemComponent(
        num: followedNum,
        name: s.Followed,
        onTap: onFollowedTap,
        formatNum: true,
      ));

      list.add(UserStatisticsItemComponent(
        num: zapNum,
        name: "Zap",
        onTap: onZapTap,
        formatNum: true,
      ));

      if (contactList != null) {
        followedTagsLength = contactList!.tagList().length;
      }
      list.add(UserStatisticsItemComponent(
          num: followedTagsLength,
          name: s.Followed_Tags,
          onTap: onFollowedTagsTap));

      if (contactList != null) {
        followedCommunitiesLength =
            contactList!.followedCommunitiesList().length;
      }
      list.add(UserStatisticsItemComponent(
          num: followedCommunitiesLength,
          name: s.Followed_Communities,
          onTap: onFollowedCommunitiesTap));

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
  }

  String? fetchLocalContactsId;

  EventMemBox? localContactBox;

  void onLongPressStart(LongPressStartDetails d) {
    if (fetchLocalContactsId == null) {
      fetchLocalContactsId = StringUtil.rndNameStr(16);
      localContactBox = EventMemBox(sortAfterAdd: false);
      var filter =
          Filter(authors: [widget.pubkey], kinds: [EventKind.CONTACT_LIST]);
      nostr!.query([filter.toJson()], (event) {
        localContactBox!.add(event);
      }, id: fetchLocalContactsId);
      BotToast.showText(text: S.of(context).Begin_to_load_Contact_History);
    }
  }

  Future<void> onLongPressEnd(LongPressEndDetails d) async {
    if (fetchLocalContactsId != null) {
      nostr!.unsubscribe(fetchLocalContactsId!);
      fetchLocalContactsId = null;

      var format = FixedDateTimeFormatter("YYYY-MM-DD hh:mm:ss");

      localContactBox!.sort();
      var list = localContactBox!.all();

      List<EnumObj> enumList = [];
      for (var event in list) {
        var _contactList = ContactList.fromJson(event.tags, event.createdAt);
        var dt = DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
        enumList.add(
            EnumObj(event, "${format.encode(dt)} (${_contactList.total()})"));
      }

      var result = await EnumSelectorComponent.show(context, enumList);
      if (result != null) {
        var event = result.value as Event;
        var _contactList = ContactList.fromJson(event.tags, event.createdAt);
        RouterUtil.router(
            context, RouterPath.USER_HISTORY_CONTACT_LIST, _contactList);
      }
    }
  }

  String queryId2 = "";

  @override
  Future<void> onReady(BuildContext context) async {
    if (!isLocal) {
      doQuery();
    }
  }

  void doQuery() {
    {
      queryId2 = StringUtil.rndNameStr(16);
      var filter = Filter(
          authors: [widget.pubkey],
          limit: 1,
          kinds: [EventKind.RELAY_LIST_METADATA]);
      nostr!.query([filter.toJson()], (event) {
        if (((relaysEvent != null &&
                    event.createdAt > relaysEvent!.createdAt) ||
                relaysEvent == null) &&
            !_disposed) {
          setState(() {
            relaysEvent = event;
            relaysTags = event.tags;
          });
        }
      }, id: queryId2);
    }
  }

  onFollowingTap() {
    if (isLocal) {
      var cl = contactListProvider.contactList;
      if (cl != null) {
        RouterUtil.router(context, RouterPath.USER_CONTACT_LIST, cl);
      }
    } else {
      var contactList = metadataProvider.getContactList(pubkey!);
      if (contactList != null) {
        RouterUtil.router(context, RouterPath.USER_CONTACT_LIST, contactList);
      }
    }
  }

  onFollowedTagsTap() {
    if (contactList != null) {
      RouterUtil.router(context, RouterPath.FOLLOWED_TAGS_LIST, contactList);
    } else if (isLocal) {
      var cl = contactListProvider.contactList;
      if (cl != null) {
        RouterUtil.router(context, RouterPath.FOLLOWED_TAGS_LIST, cl);
      }
    }
  }

  String followedSubscribeId = "";

  onFollowedTap() {
    if (followedMap == null) {
      // load data
      followedMap = {};
      // pull zap event
      Map<String, dynamic> filter = {};
      filter["kinds"] = [EventKind.CONTACT_LIST];
      filter["#p"] = [widget.pubkey];
      followedSubscribeId = StringUtil.rndNameStr(12);
      nostr!.query([filter], (e) {
        var oldEvent = followedMap![e.pubkey];
        if (oldEvent == null || e.createdAt > oldEvent.createdAt) {
          followedMap![e.pubkey] = e;

          setState(() {
            followedNum = followedMap!.length;
          });
        }
      }, id: followedSubscribeId);

      followedNum = 0;
    } else {
      // jump to see
      var pubkeys = followedMap!.keys.toList();
      RouterUtil.router(context, RouterPath.FOLLOWED, pubkeys);
    }
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
      var filter = Filter(kinds: [EventKind.ZAP], p: [widget.pubkey]);
      zapSubscribeId = StringUtil.rndNameStr(12);
      // print(filter);
      nostr!.query([filter.toJson()], onZapEvent, id: zapSubscribeId);

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
    if (event.kind == EventKind.ZAP && zapEventBox!.add(event)) {
      setState(() {
        zapNum = zapNum! + ZapInfoUtil.getNumFromZapEvent(event);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    _disposed = true;
    checkAndUnsubscribe(queryId2);
    checkAndUnsubscribe(zapSubscribeId);
  }

  void checkAndUnsubscribe(String queryId) {
    if (StringUtil.isNotBlank(queryId)) {
      try {
        nostr!.unsubscribe(queryId);
      } catch (e) {}
    }
  }

  bool _disposed = false;

  onFollowedCommunitiesTap() {
    if (contactList != null) {
      RouterUtil.router(context, RouterPath.FOLLOWED_COMMUNITIES, contactList);
    } else if (isLocal) {
      var cl = contactListProvider.contactList;
      if (cl != null) {
        RouterUtil.router(context, RouterPath.FOLLOWED_COMMUNITIES, cl);
      }
    }
  }
}

class UserStatisticsItemComponent extends StatelessWidget {
  int? num;

  String name;

  Function onTap;

  bool formatNum;

  Function(LongPressStartDetails)? onLongPressStart;

  Function(LongPressEndDetails)? onLongPressEnd;

  UserStatisticsItemComponent({
    required this.num,
    required this.name,
    required this.onTap,
    this.formatNum = false,
    this.onLongPressStart,
    this.onLongPressEnd,
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
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: Container(
        margin: EdgeInsets.only(left: Base.BASE_PADDING),
        child: Row(children: list),
      ),
    );
  }
}
