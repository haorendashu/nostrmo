import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/zap/zap_info_util.dart';
import 'package:nostrmo/component/user/user_pic_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/number_format_util.dart';
import 'package:nostrmo/util/router_util.dart';

class EventTopZapsComponent extends StatefulWidget {
  List<Event> zapEvents;

  EventTopZapsComponent(this.zapEvents);

  @override
  State<StatefulWidget> createState() {
    return _EventTopZapsComponent();
  }
}

class _EventTopZapsComponent extends State<EventTopZapsComponent> {
  double TOP_HEADER_IMAGE_WIDTH = 34;

  double HEADER_IMAGE_WIDTH = 22;

  int SHOW_LIMIT = 5;

  @override
  Widget build(BuildContext context) {
    if (widget.zapEvents.isEmpty) {
      return Container();
    }

    List<EventTopZapInfo> zapInfos = [];
    for (var zapEvent in widget.zapEvents) {
      var zapNum = ZapInfoUtil.getNumFromZapEvent(zapEvent);
      var pubkey = ZapInfoUtil.parseSenderPubkey(zapEvent);
      pubkey ??= zapEvent.pubkey;
      zapInfos.add(EventTopZapInfo(pubkey, zapNum));
    }

    zapInfos.sort((a, b) {
      return b.zapNum - a.zapNum;
    });

    List<Widget> list = [];

    List<Widget> topList = [];
    topList.add(Container(
      child: const Icon(
        Icons.bolt,
        color: Colors.orange,
      ),
    ));
    topList.add(GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.USER, zapInfos[0].pubkey);
      },
      child: UserPicComponent(
        pubkey: zapInfos[0].pubkey,
        width: TOP_HEADER_IMAGE_WIDTH,
      ),
    ));
    list.add(Row(
      mainAxisSize: MainAxisSize.min,
      children: topList,
    ));

    list.add(Container(
      margin: const EdgeInsets.only(
        left: Base.BASE_PADDING_HALF,
        right: Base.BASE_PADDING,
      ),
      child: Text(
        NumberFormatUtil.format(zapInfos[0].zapNum),
        style: const TextStyle(
          color: Colors.orange,
        ),
      ),
    ));

    var zapInfosLength = zapInfos.length;
    if (zapInfosLength < SHOW_LIMIT) {
      for (var i = 1; i < zapInfosLength; i++) {
        list.add(buildUserPic(zapInfos[i].pubkey, HEADER_IMAGE_WIDTH));
      }
    } else {
      for (var i = 1; i < SHOW_LIMIT; i++) {
        list.add(buildUserPic(zapInfos[i].pubkey, HEADER_IMAGE_WIDTH));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: list,
    );
  }

  Widget buildUserPic(String pubkey, double width) {
    return Container(
      margin: const EdgeInsets.only(right: Base.BASE_PADDING_HALF),
      child: GestureDetector(
        onTap: () {
          RouterUtil.router(context, RouterPath.USER, pubkey);
        },
        child: UserPicComponent(
          pubkey: pubkey,
          width: width,
        ),
      ),
    );
  }
}

class EventTopZapInfo {
  final String pubkey;

  final int zapNum;

  EventTopZapInfo(this.pubkey, this.zapNum);
}
