import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostr_sdk/nip19/nip19_tlv.dart';
import 'package:nostr_sdk/nip51/follow_set.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/image_component.dart';
import 'package:nostrmo/component/tag_component.dart';
import 'package:nostrmo/component/user/name_component.dart';
import 'package:nostrmo/component/user/simple_metadata_component.dart';
import 'package:nostrmo/component/user/user_pic_component.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';

class StarterPacksDetailRouter extends StatefulWidget {
  StarterPacksDetailRouter({super.key});

  @override
  State<StarterPacksDetailRouter> createState() =>
      _StarterPacksDetailRouterState();
}

class _StarterPacksDetailRouterState extends State<StarterPacksDetailRouter> {
  late S s;

  FollowSet? followSet;

  @override
  Widget build(BuildContext context) {
    s = S.of(context);
    var argItf = RouterUtil.routerArgs(context);
    if (argItf == null || argItf is! FollowSet) {
      RouterUtil.back(context);
      return Container();
    }
    followSet = argItf;
    var followList = followSet!.list();
    var followListLength = followList.length;

    var themeData = Theme.of(context);
    var largeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    var margin = const EdgeInsets.only(
      top: 20,
    );
    List<Widget> list = [];
    if (StringUtil.isNotBlank(followSet!.image)) {
      list.add(Container(
        height: 180,
        width: double.infinity,
        child: ImageComponent(
          imageUrl: followSet!.image!,
          fit: BoxFit.cover,
        ),
      ));
    }

    list.add(Container(
      margin: margin,
      child: SelectableText(
        followSet!.displayName(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: largeFontSize,
        ),
      ),
    ));

    if (followSet != null && followSet!.tagList().isNotEmpty) {
      List<Widget> tagWidgets = [];
      for (var tag in followSet!.tagList()) {
        tagWidgets.add(TagComponent(
          tag: tag,
          jumpable: false,
        ));
      }

      list.add(Container(
        margin: margin,
        child: Wrap(
          spacing: Base.BASE_PADDING,
          runSpacing: Base.BASE_PADDING,
          children: tagWidgets,
        ),
      ));
    }

    if (StringUtil.isNotBlank(followSet!.description)) {
      list.add(Container(
        margin: margin,
        child: Text(followSet!.description!),
      ));
    }

    list.add(Container(
      margin: margin,
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.only(right: Base.BASE_PADDING),
            child: Text("${s.Created_by}: "),
          ),
          GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.USER, followSet!.pubkey);
            },
            behavior: HitTestBehavior.translucent,
            child: Selector<MetadataProvider, Metadata?>(
                builder: (context, metadata, child) {
              return Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(
                        left: Base.BASE_PADDING_HALF,
                        right: Base.BASE_PADDING_HALF),
                    child: UserPicComponent(
                        pubkey: followSet!.pubkey,
                        width: 24,
                        metadata: metadata),
                  ),
                  NameComponent(
                    pubkey: followSet!.pubkey,
                    metadata: metadata,
                    maxLines: 1,
                    textOverflow: TextOverflow.ellipsis,
                    showName: false,
                  ),
                ],
              );
            }, selector: (context, _provider) {
              return _provider.getMetadata(followSet!.pubkey);
            }),
          ),
        ],
      ),
    ));

    double middleWidth = 20;

    list.add(Container(
      margin: margin,
      child: Row(
        children: [
          Expanded(
              child: Text("${s.Updated}: ${GetTimeAgo.parse(
            DateTime.fromMillisecondsSinceEpoch(followSet!.createdAt * 1000),
            pattern: "dd MMM, yyyy",
          )}")),
          Container(
            width: middleWidth,
          ),
          Expanded(child: Text("${s.Users}: $followListLength")),
        ],
      ),
    ));

    list.add(Container(
      margin: margin,
      child: Row(
        children: [
          Expanded(
              child: Container(
            child: FilledButton(
              onPressed: followAll,
              child: Text("Follow All"),
            ),
          )),
          Container(
            width: middleWidth,
          ),
          Expanded(
              child: Container(
            child: FilledButton(
              onPressed: () {
                RouterUtil.router(
                    context, RouterPath.FOLLOW_SET_FEED, followSet);
              },
              child: Text("Show Feed"),
            ),
          )),
        ],
      ),
    ));

    list.add(Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      child: Divider(),
    ));

    for (var follow in followList) {
      list.add(Container(
        margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        child: GestureDetector(
          onTap: () {
            RouterUtil.router(context, RouterPath.USER, follow.publicKey);
          },
          child: SimpleMetadataComponent(
              pubkey: follow.publicKey, showFollow: true),
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          followSet!.displayName(),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: themeData.textTheme.bodyLarge!.fontSize),
        ),
        actions: [
          PopupMenuButton(
            onSelected: onPopMenuSelected,
            tooltip: s.More,
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: "copyNaddr",
                  child: Row(
                    children: [
                      Icon(Icons.copy),
                      Text(" ${s.Copy} ${s.Address}")
                    ],
                  ),
                ),
              ];
            },
            child: Container(
              padding: const EdgeInsets.only(
                left: Base.BASE_PADDING_HALF,
                right: Base.BASE_PADDING_HALF,
              ),
              child: const Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: list,
          ),
        ),
      ),
    );
  }

  void onPopMenuSelected(value) {
    if (value == "copyNaddr") {
      var naddr = followSet!.getNaddr();
      print(naddr.toString());
      Clipboard.setData(ClipboardData(text: NIP19Tlv.encodeNaddr(naddr)));
      BotToast.showText(text: S.of(context).Copy_success);
    }
  }

  void followAll() {
    if (followSet != null) {
      contactListProvider.addContacts(followSet!.list().toList());
    }
  }
}
