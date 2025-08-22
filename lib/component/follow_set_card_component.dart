import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostr_sdk/nip51/follow_set.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/image_component.dart';
import 'package:nostrmo/component/user/name_component.dart';
import 'package:nostrmo/component/user/user_pic_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../generated/l10n.dart';

class FollowSetCardComponent extends StatefulWidget {
  FollowSet followSet;

  FollowSetCardComponent(this.followSet);

  @override
  State<StatefulWidget> createState() {
    return _FollowSetCardComponent();
  }
}

class _FollowSetCardComponent extends State<FollowSetCardComponent> {
  double topHeight = 110;

  double bottomHeight = 130;

  double bottomUserPicWidth = 24;

  late S s;

  @override
  Widget build(BuildContext context) {
    s = S.of(context);
    var themeData = Theme.of(context);
    List<Widget> list = [];

    list.add(Container(
      height: topHeight,
      color: Colors.grey,
      child: StringUtil.isNotBlank(widget.followSet.image)
          ? ImageComponent(
              imageUrl: widget.followSet.image!,
              width: double.infinity,
              height: topHeight,
              fit: BoxFit.cover,
            )
          : null,
    ));

    List<Widget> bottomList = [];
    if (StringUtil.isNotBlank(widget.followSet.title)) {
      bottomList.add(Text(
        widget.followSet.title!,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: themeData.textTheme.bodyLarge!.fontSize,
          fontWeight: FontWeight.bold,
        ),
      ));
    }

    bottomList.add(Expanded(
        child: Container(
      child: GestureDetector(
        onTap: () {
          RouterUtil.router(context, RouterPath.USER, widget.followSet.pubkey);
          return;
        },
        behavior: HitTestBehavior.translucent,
        child: Selector<MetadataProvider, Metadata?>(
            builder: (context, metadata, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(right: Base.BASE_PADDING_HALF),
                child: UserPicComponent(
                  pubkey: widget.followSet.pubkey,
                  width: 30,
                  metadata: metadata,
                ),
              ),
              Container(
                child: NameComponent(
                  pubkey: widget.followSet.pubkey,
                  metadata: metadata,
                  showName: false,
                ),
              ),
            ],
          );
        }, selector: (context, _provider) {
          return _provider.getMetadata(widget.followSet.pubkey);
        }),
      ),
    )));

    var index = 0;
    var follows = widget.followSet.list();
    List<Widget> followsList = [];
    for (var follow in follows) {
      followsList.add(
        Positioned(
          left: index * bottomUserPicWidth - index * 5,
          child: UserPicComponent(
            pubkey: follow.publicKey,
            width: bottomUserPicWidth,
          ),
        ),
      );

      index++;
      if (index >= 6) {
        break;
      }
    }

    var bottomRightTextStyle = TextStyle(
      fontSize: themeData.textTheme.bodySmall!.fontSize,
      color: themeData.hintColor,
    );
    bottomList.add(Container(
      child: Row(
        children: [
          Container(
            width: 150,
            height: bottomUserPicWidth,
            child: Stack(
              alignment: Alignment.center,
              children: followsList,
            ),
          ),
          Expanded(child: Container()),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${follows.length} ${s.Users}",
                  style: bottomRightTextStyle,
                ),
                Text(
                  "${GetTimeAgo.parse(
                    DateTime.fromMillisecondsSinceEpoch(
                        widget.followSet.createdAt * 1000),
                    pattern: "dd MMM, yyyy",
                  )} ${s.Updated}",
                  style: bottomRightTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    ));

    list.add(Container(
      height: bottomHeight,
      color: themeData.hintColor.withValues(alpha: 0.3),
      // color: themeData.cardColor,
      padding: EdgeInsets.all(Base.BASE_PADDING),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: bottomList,
      ),
    ));

    return GestureDetector(
      onTap: () {
        RouterUtil.router(
            context, RouterPath.FOLLOW_SET_FEED, widget.followSet);
      },
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: list,
        ),
      ),
    );
  }
}
