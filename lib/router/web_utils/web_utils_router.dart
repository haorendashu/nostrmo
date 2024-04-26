import 'dart:convert';

import 'package:flutter/material.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/dio_util.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';
import 'web_util_item_component.dart';

class WebUtilsRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _WebUtilsRouter();
  }
}

class _WebUtilsRouter extends CustState<WebUtilsRouter> {
  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);
    var s = S.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [
      // WebUtilItemComponent(
      //   link: "https://nostr.band/",
      //   des:
      //       "Nostr.Band is a collection of services for this new emerging network. It has a full-text search, a NIP-05 names provider, and more stuff coming soon.",
      // ),
      // WebUtilItemComponent(
      //   link: "https://wavman.app/",
      //   des:
      //       "An open-source music player built for Nostr, brought to you by the good folks at Wavlake.",
      // ),
      // WebUtilItemComponent(
      //   link: "https://zapstr.live/",
      //   des:
      //       "Zapstr is a design-only concept (for now) of a music platform that allows artists to own their audience (thanks to nostr) and monetize their music with zaps and streams. It also acts as a discovery platform for everyone else.",
      // ),
      // WebUtilItemComponent(
      //   link: "https://kind3.xyz/",
      //   des:
      //       "This is a tool to change your Nostr follow list.It's an experiment to help you peak out of your echo chamber.",
      // ),
      // WebUtilItemComponent(
      //   link: "https://heguro.github.io/nostr-following-list-util/",
      //   des:
      //       "Nostr Following List Util: Tools to collect and resend following lists from relays.",
      // ),
      // WebUtilItemComponent(
      //   link: "https://badges.page/",
      //   des: "A tool for Manage Nostr Badges.",
      // ),
      // WebUtilItemComponent(
      //   link: "https://nostr.directory/",
      //   des: "Verify NIP-05 with your twitter.",
      // ),
      // WebUtilItemComponent(
      //   link: "https://metadata.nostr.com/",
      //   des: "Nostr Profile Manager. Backup / Refine / Restore profile events.",
      // ),
      // WebUtilItemComponent(
      //   link: "https://snowcait.github.io/nostr-playground/",
      //   des: "A Nostr playground.",
      // ),
      // WebUtilItemComponent(
      //   link: "https://flycat.club/",
      //   des: "Blogging on Nostr right away and it is a nostr client too.",
      // ),
    ];

    for (var item in webUtils) {
      list.add(WebUtilItemComponent(link: item.link, des: item.des));
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          s.Web_Utils,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: list,
        ),
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    load();
  }

  List<WebUtilItem> webUtils = [];

  Future<void> load() async {
    var str = await DioUtil.getStr(Base.WEB_TOOLS);
    if (StringUtil.isNotBlank(str)) {
      var itfs = jsonDecode(str!);
      webUtils = [];
      for (var itf in itfs) {
        if (itf is Map) {
          webUtils.add(WebUtilItem(itf["link"], itf["des"]));
        }
      }
      setState(() {});
    }
  }
}

class WebUtilItem {
  String link;
  String des;

  WebUtilItem(this.link, this.des);
}
