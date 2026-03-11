import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/webview_router.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../generated/l10n.dart';
import '../../util/dio_util.dart';
import '../../util/router_util.dart';
import 'web_app_item.dart';
import 'web_app_item_component.dart';
import 'web_app_types.dart';

class WebAppsRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return WebAppsRouterState();
  }
}

class WebAppsRouterState extends CustState<WebAppsRouter> {
  late S s;

  List<WebAppItem> items = [];

  Map<String, int> selectedMap = {};

  List<EnumObj> typeEnums = [];

  @override
  Widget doBuild(BuildContext context) {
    s = S.of(context);
    var themeData = Theme.of(context);

    if (typeEnums.isEmpty) {
      typeEnums.add(EnumObj(WebAppTypes.NOTES, s.Notes));
      typeEnums.add(EnumObj(WebAppTypes.LONG_FORM, s.Long_Form));
      typeEnums.add(EnumObj(WebAppTypes.GROUP_CHAT, s.Group_Chat));
      typeEnums.add(EnumObj(WebAppTypes.TOOLS, s.Tools));
      typeEnums.add(EnumObj(WebAppTypes.PHOTOS, s.Photos));
      typeEnums.add(EnumObj(WebAppTypes.STREAMING, s.Streaming));
      typeEnums.add(EnumObj(WebAppTypes.ZAPS, s.Zaps));
      typeEnums.add(EnumObj(WebAppTypes.MARKETPLACES, s.Marketplaces));
      typeEnums.add(EnumObj(WebAppTypes.OTHERS, s.Others));
    }

    List<Widget> list = [];

    List<Widget> typeWidgetList = [];
    typeWidgetList
        .add(buildTypeWidget(EnumObj("all", s.All), selectedMap.isEmpty, () {
      if (selectedMap.isNotEmpty) {
        setState(() {
          selectedMap.clear();
        });
      }
    }));
    for (var typeEnum in typeEnums) {
      var selected = selectedMap[typeEnum.value] != null;
      typeWidgetList.add(buildTypeWidget(typeEnum, selected, () {
        if (selected) {
          setState(() {
            selectedMap.remove(typeEnum.value);
          });
        } else {
          setState(() {
            selectedMap[typeEnum.value] = 1;
          });
        }
      }));
    }
    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      child: Wrap(
        children: typeWidgetList,
      ),
    ));

    List<WebAppItem> showItems = [];
    if (selectedMap.isNotEmpty) {
      for (var item in items) {
        for (var typeValue in item.types) {
          if (selectedMap[typeValue] != null) {
            showItems.add(item);
            break;
          }
        }
      }
    } else {
      showItems.addAll(items);
    }

    List<Widget> itemWidgetList = [];
    if (PlatformUtil.isPC()) {
      for (var i = 0; i < showItems.length; i += 2) {
        var item = showItems[i];
        if (i + 1 < showItems.length) {
          var item1 = showItems[i + 1];
          itemWidgetList.add(Container(
            child: Row(
              children: [
                Expanded(child: WebAppItemComponent(item, onTap: onTap)),
                Expanded(child: WebAppItemComponent(item1, onTap: onTap)),
              ],
            ),
          ));
        } else {
          itemWidgetList.add(Container(
            child: Row(
              children: [
                Expanded(child: WebAppItemComponent(item, onTap: onTap)),
                Expanded(child: Container()),
              ],
            ),
          ));
        }
      }
    } else {
      for (var item in showItems) {
        itemWidgetList.add(WebAppItemComponent(item, onTap: onTap));
      }
    }

    list.add(Expanded(
      child: Container(
        child: SingleChildScrollView(
          child: Column(
            children: itemWidgetList,
          ),
        ),
      ),
    ));

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          "Web APPs",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: themeData.textTheme.bodyLarge!.fontSize,
          ),
        ),
      ),
      body: Column(
        children: list,
      ),
    );
  }

  void onTap(WebAppItem item) {
    WebViewRouter.open(context, item.link);
    RouterUtil.back(context);
  }

  @override
  Future<void> onReady(BuildContext context) async {
    load();
  }

  Future<void> load() async {
    var str = await DioUtil.getStr(Base.WEB_APPS);
    if (StringUtil.isNotBlank(str)) {
      var jsonList = jsonDecode(str!);
      if (jsonList is List) {
        items.clear();

        for (var jsonObj in jsonList) {
          var link = jsonObj["link"];
          var name = jsonObj["name"];
          var desc = jsonObj["desc"];
          var types = jsonObj["types"];
          var image = jsonObj["image"];

          // print(link);
          // print(name);
          // print(desc);
          // print(types);
          // print(types! is List);
          // print(image);

          if (StringUtil.isBlank(link) ||
              StringUtil.isBlank(name) ||
              StringUtil.isBlank(desc) ||
              types is! List) {
            continue;
          }

          items.add(WebAppItem(
              link, name, desc, types.map((item) => item.toString()).toList(),
              image: image));
        }
      }
    }

    setState(() {});
  }

  Widget buildTypeWidget(EnumObj enumObj, bool selected, Function onTap) {
    return Container(
      child: GestureDetector(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              child: Checkbox(
                value: selected,
                onChanged: (_) {
                  onTap();
                },
              ),
            ),
            Container(
              child: Text(enumObj.name),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    if (items.isEmpty) {
      items.add(WebAppItem(
        "https://app.flotilla.social/",
        "Flotilla",
        "Relay chat client",
        [WebAppTypes.GROUP_CHAT],
        image: "https://nowser.nostrmo.com/images/apps/flotilla.png",
      ));
      items.add(WebAppItem(
        "https://www.zapplepay.com/",
        "Zapplepay",
        "Zap from any client 🖕",
        [WebAppTypes.TOOLS],
        image: "https://nowser.nostrmo.com/images/apps/zapplepay.png",
      ));
      items.add(WebAppItem(
        "https://habla.news/",
        "Habla",
        "A long form content client for nostr notes",
        [WebAppTypes.LONG_FORM],
        image: "https://nowser.nostrmo.com/images/apps/habla.png",
      ));
      items.add(WebAppItem(
        "https://listr.lol/",
        "Listr",
        "Create nostr lists",
        [WebAppTypes.TOOLS],
        image: "https://nowser.nostrmo.com/images/apps/listr.png",
      ));
      items.add(WebAppItem(
        "https://groups.nip29.com/",
        "Groups",
        "A relay-based NIP-29 group chat client",
        [WebAppTypes.GROUP_CHAT],
        image: "https://nowser.nostrmo.com/images/apps/groups.png",
      ));
      items.add(WebAppItem(
        "https://lumilumi.app/",
        "lumilumi",
        "Switch between full and low-data modes — a flexible Nostr web client",
        [WebAppTypes.NOTES],
        image: "https://nowser.nostrmo.com/images/apps/lumilumi.ico",
      ));
      items.add(WebAppItem(
        "https://iris.to/",
        "Iris",
        "Simple and fast web client",
        [WebAppTypes.NOTES],
        image: "https://nowser.nostrmo.com/images/apps/iris.png",
      ));
      items.add(WebAppItem(
        "https://nostter.app/",
        "Nostter",
        "Calm social client",
        [WebAppTypes.NOTES],
        image: "https://nowser.nostrmo.com/images/apps/nostter.png",
      ));
      items.add(WebAppItem(
        "https://www.getwired.app/",
        "Wired",
        "An anonymous-first agora",
        [WebAppTypes.NOTES],
        image: "https://nowser.nostrmo.com/images/apps/wired.png",
      ));
      items.add(WebAppItem(
        "https://emojito.meme/",
        "Emojito",
        "Create custom emoji sets",
        [WebAppTypes.TOOLS],
        image: "https://nowser.nostrmo.com/images/apps/emojito.png",
      ));
      items.add(WebAppItem(
        "https://formstr.app/",
        "Formstr",
        "Create and share forms",
        [WebAppTypes.TOOLS],
        image: "https://nowser.nostrmo.com/images/apps/formstr.png",
      ));
      items.add(WebAppItem(
        "https://coracle.social/",
        "Coracle",
        "Nostr, the easy way.",
        [WebAppTypes.NOTES],
        image: "https://nowser.nostrmo.com/images/apps/coracle.png",
      ));
      items.add(WebAppItem(
        "https://badges.page/",
        "Badges",
        "A manager for your nostr badges",
        [WebAppTypes.TOOLS],
        image: "https://nowser.nostrmo.com/images/apps/badges.png",
      ));
      items.add(WebAppItem(
        "https://olas.app/",
        "Olas",
        "Olas is a client for publishing and looking at photos",
        [WebAppTypes.NOTES],
        image: "https://nowser.nostrmo.com/images/apps/olas.png",
      ));
      items.add(WebAppItem(
        "https://nsec.app/",
        "Nsec",
        "Use Nostr apps safely",
        [WebAppTypes.TOOLS],
        image: "https://nowser.nostrmo.com/images/apps/nsec.png",
      ));
      items.add(WebAppItem(
        "https://chachi.chat/",
        "Nsec",
        "A group chat and generic NIP-29 group posts client",
        [WebAppTypes.GROUP_CHAT],
        image: "https://nowser.nostrmo.com/images/apps/chachi.png",
      ));
      items.add(WebAppItem(
        "https://oddbean.com/",
        "Oddbean",
        "Hacker News style client",
        [WebAppTypes.NOTES],
        image: "https://nowser.nostrmo.com/images/apps/oddbean.png",
      ));
      items.add(WebAppItem(
        "https://getalby.com/",
        "Alby",
        "Your bitcoin and nostr companion for the web",
        [WebAppTypes.ZAPS],
        image: "https://nowser.nostrmo.com/images/apps/alby.png",
      ));
      items.add(WebAppItem(
        "https://jumble.social/",
        "Jumble",
        "Jumble is a client focused on browsing relay feeds",
        [WebAppTypes.NOTES],
        image: "https://nowser.nostrmo.com/images/apps/jumble.png",
      ));
      items.add(WebAppItem(
        "https://yakihonne.com/",
        "Yakihonne",
        "Publish and curate long-form content",
        [WebAppTypes.NOTES, WebAppTypes.LONG_FORM],
        image: "https://nowser.nostrmo.com/images/apps/yakihonne.png",
      ));
      items.add(WebAppItem(
        "https://flycat.club/",
        "Flycat",
        "Explore Nostr universe and long form content",
        [WebAppTypes.LONG_FORM],
        image: "https://nowser.nostrmo.com/images/apps/flycat.png",
      ));
      items.add(WebAppItem(
        "https://zap.stream/",
        "Zapstream",
        "Live stream and zap",
        [WebAppTypes.STREAMING],
        image: "https://nowser.nostrmo.com/images/apps/zapstream.png",
      ));
      items.add(WebAppItem(
        "https://bouquet.slidestr.net/",
        "Bouquet",
        "A personal manager for Blossom media servers",
        [WebAppTypes.PHOTOS],
        image: "https://nowser.nostrmo.com/images/apps/bouquet.png",
      ));
      items.add(WebAppItem(
        "https://shopstr.store/",
        "Shopstr",
        "Buy and sell for sats over nostr",
        [WebAppTypes.MARKETPLACES],
        image: "https://nowser.nostrmo.com/images/apps/shopstr.png",
      ));
      items.add(WebAppItem(
        "https://ostrich.work/",
        "Ostrich Work",
        "Job Board over Nostr",
        [WebAppTypes.OTHERS],
        image: "https://nowser.nostrmo.com/images/apps/ostrich.png",
      ));
      items.add(WebAppItem(
        "https://web.nostrmo.com/",
        "Nostrmo",
        "A nostr client for Web, iOS, Android, MacOS and Windows.",
        [WebAppTypes.NOTES],
        image: "https://nowser.nostrmo.com/images/apps/nostrmo.png",
      ));
      items.add(WebAppItem(
        "https://alphaama.com/",
        "alphaama",
        "just a nostr fucking client, CLI + GUI",
        [WebAppTypes.NOTES],
      ));
      items.add(WebAppItem(
        "https://pinstr.app/",
        "Pinstr",
        "Like Pinterest but on nostr with zaps",
        [WebAppTypes.PHOTOS],
        image: "https://nowser.nostrmo.com/images/apps/pinstr.png",
      ));
      items.add(WebAppItem(
        "https://wikifreedia.xyz/",
        "Wikifreedia",
        "a client for the wikipedia idea built on Nostr",
        [WebAppTypes.OTHERS],
        image: "https://nowser.nostrmo.com/images/apps/wikifreedia.png",
      ));
      items.add(WebAppItem(
        "https://go.yondar.me/",
        "Yondar",
        "The social map",
        [WebAppTypes.OTHERS],
        image: "https://nowser.nostrmo.com/images/apps/yondar.png",
      ));
      items.add(WebAppItem(
        "https://nostr.band/",
        "Nostr Band",
        "Nostr data and statistics advanced search.",
        [WebAppTypes.OTHERS],
        image: "https://nowser.nostrmo.com/images/apps/nostrband.png",
      ));
      items.add(WebAppItem(
        "https://nostrudel.ninja/",
        "noStrudel",
        "The jack of all trades",
        [WebAppTypes.NOTES],
        image: "https://nowser.nostrmo.com/images/apps/nostrudel.png",
      ));
      items.add(WebAppItem(
        "https://nostrnests.com/",
        "Nests",
        "Audio rooms",
        [WebAppTypes.STREAMING],
        image: "https://nowser.nostrmo.com/images/apps/nostrnests.png",
      ));
      items.add(WebAppItem(
        "https://wikistr.com/",
        "Wikistr",
        "A NIP-54 'wiki' client with multi-article view",
        [WebAppTypes.OTHERS],
        image: "https://nowser.nostrmo.com/images/apps/wikistr.png",
      ));
      items.add(WebAppItem(
        "https://slidestr.net/",
        "Slidestr",
        "Immersive media browsing",
        [WebAppTypes.PHOTOS],
        image: "https://nowser.nostrmo.com/images/apps/slidestr.png",
      ));
      items.add(WebAppItem(
        "https://www.coolr.chat/",
        "Coolr",
        "A minimalist, IRC like chat app built on Nostr. Fast and temporary.",
        [WebAppTypes.GROUP_CHAT],
        image: "https://nowser.nostrmo.com/images/apps/coolr.png",
      ));
      items.add(WebAppItem(
        "https://sendbox.nostrmo.com/",
        "Sendbox",
        "This is a tool to help you delayed publish your nostr event.",
        [WebAppTypes.TOOLS],
      ));
      items.add(WebAppItem(
        "https://www.coinos.io/",
        "Coinos",
        "The easiest way to get started with bitcoin. A free web wallet and payment page for everyone.",
        [WebAppTypes.ZAPS],
      ));
      items.add(WebAppItem(
        "https://shipyard.pub/",
        "Shipyard",
        "Schedule notes",
        [WebAppTypes.TOOLS],
      ));
      items.add(WebAppItem(
        "https://npub.pro/",
        "NpubPro",
        "Beautiful nostr-based websites for creators.Best way to share your work outside of nostr.",
        [WebAppTypes.LONG_FORM],
      ));
      items.add(WebAppItem(
        "https://write.nostr.com/",
        "Write Nostr",
        "A tool to send Markdown long-format or blog post notes using NIP-23.",
        [WebAppTypes.LONG_FORM],
      ));
      items.add(WebAppItem(
        "https://nosli.vercel.app/",
        "Nosli",
        "Nosli helps you create a curated list of posts on nostr.",
        [WebAppTypes.LONG_FORM],
      ));
      items.add(WebAppItem(
        "https://primal.net/",
        "Primal",
        "A Multi-platform client",
        [WebAppTypes.NOTES],
      ));
      items.add(WebAppItem(
        "https://nostr.build/",
        "Nostr Build",
        "Nostr media uploader",
        [WebAppTypes.PHOTOS],
      ));
      items.add(WebAppItem(
        "https://nostrplebs.com/",
        "Nostr Plebs",
        "An easy way of getting a NIP-05 identifier/Nostr Address and other Nostr services.",
        [WebAppTypes.TOOLS],
      ));
      items.add(WebAppItem(
        "https://nostrnests.com/",
        "Nostr Nests",
        "Join this audio Space",
        [WebAppTypes.TOOLS],
      ));
      items.add(WebAppItem(
        "https://zappix.app/",
        "Zappix",
        "Social Media on Nostr",
        [WebAppTypes.PHOTOS],
        image: "https://nowser.nostrmo.com/images/apps/zappix.png",
      ));
      items.add(WebAppItem(
        "https://following.space/",
        "Following Space",
        "Create, share, and discover Nostr Follow Packs",
        [WebAppTypes.OTHERS],
        image: "https://nowser.nostrmo.com/images/apps/following_space.png",
      ));
      items.add(WebAppItem(
        "https://nosotros.app/",
        "Nosotros",
        "A decentralized social network based on nostr protocol",
        [WebAppTypes.NOTES],
        image: "https://nowser.nostrmo.com/images/apps/nosotros.ico",
      ));
      items.add(WebAppItem(
        "https://npub.cash/",
        "npub.cash",
        "A nostr native Lightning Address for everyone",
        [WebAppTypes.ZAPS],
        image: "https://nowser.nostrmo.com/images/apps/npubcash.ico",
      ));
      items.add(WebAppItem(
        "https://asknostr.site/",
        "asknostr",
        "This website is a Q&A community on top of Nostr.",
        [WebAppTypes.NOTES],
        image: "https://nowser.nostrmo.com/images/apps/asknostr_site.png",
      ));

      List<Map> jsonList = [];
      for (var item in items) {
        jsonList.add(item.toJson());
      }
      log(jsonEncode(jsonList));

      // setState(() {});
    }
  }
}
