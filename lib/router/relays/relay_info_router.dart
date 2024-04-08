import 'dart:convert';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/relay_local/relay_local.dart';
import 'package:nostrmo/component/name_component.dart';
import 'package:nostrmo/component/user_pic_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:provider/provider.dart';

import '../../client/nip19/nip19.dart';
import '../../client/relay/relay.dart';
import '../../component/image_component.dart';
import '../../component/webview_router.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';

class RelayInfoRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RelayInfoRouter();
  }
}

class _RelayInfoRouter extends State<RelayInfoRouter> {
  double IMAGE_WIDTH = 45;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var mainColor = themeData.primaryColor;
    var s = S.of(context);

    var relayItf = RouterUtil.routerArgs(context);
    if (relayItf == null || !(relayItf is Relay)) {
      RouterUtil.back(context);
      return Container();
    }

    var relay = relayItf as Relay;
    var relayInfo = relay.info!;
    bool isMyRelay = false;
    if (nostr!.getRelay(relay.relayStatus.addr) != null) {
      isMyRelay = true;
    }

    List<Widget> list = [];

    list.add(Container(
      margin: EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      child: Text(
        relayInfo.name,
        style: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(
        bottom: Base.BASE_PADDING,
      ),
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: Text(relayInfo.description),
    ));

    list.add(RelayInfoItemComponent(
      title: s.Url,
      child: SelectableText(relay.url),
    ));

    list.add(RelayInfoItemComponent(
      title: s.Owner,
      child: Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
          List<Widget> list = [];

          Widget? imageWidget;
          if (metadata != null) {
            imageWidget = ImageComponent(
              imageUrl: metadata.picture!,
              width: IMAGE_WIDTH,
              height: IMAGE_WIDTH,
              fit: BoxFit.cover,
              placeholder: (context, url) => CircularProgressIndicator(),
            );
          }
          list.add(Container(
            alignment: Alignment.center,
            height: IMAGE_WIDTH,
            width: IMAGE_WIDTH,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
              color: Colors.grey,
            ),
            child: imageWidget,
          ));

          list.add(Container(
            margin: EdgeInsets.only(left: Base.BASE_PADDING),
            child: NameComponnet(
              pubkey: relayInfo.pubKey,
              metadata: metadata,
            ),
          ));

          return GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.USER, relayInfo.pubKey);
            },
            child: Row(
              children: list,
            ),
          );
        },
        selector: (context, _provider) {
          return _provider.getMetadata(relayInfo.pubKey);
        },
      ),
    ));

    list.add(RelayInfoItemComponent(
      title: s.Contact,
      child: SelectableText(relayInfo.contact),
    ));

    list.add(RelayInfoItemComponent(
      title: s.Soft,
      child: SelectableText(relayInfo.software),
    ));

    list.add(RelayInfoItemComponent(
      title: s.Version,
      child: SelectableText(relayInfo.version),
    ));

    List<Widget> nipWidgets = [];
    for (var nip in relayInfo.nips) {
      nipWidgets.add(NipComponent(nip: nip));
    }
    list.add(RelayInfoItemComponent(
      title: "NIPs",
      child: Wrap(
        children: nipWidgets,
        spacing: Base.BASE_PADDING,
        runSpacing: Base.BASE_PADDING,
      ),
    ));

    if (relay is! RelayLocal && isMyRelay) {
      list.add(Container(
        child: CheckboxListTile(
          title: Text(s.Write),
          value: relay.relayStatus.writeAccess,
          onChanged: (bool? value) {
            if (value != null) {
              relay.relayStatus.writeAccess = value;
              setState(() {});
              relayProvider.saveRelay();
            }
          },
        ),
      ));

      list.add(Container(
        child: CheckboxListTile(
          title: Text(s.Read),
          value: relay.relayStatus.readAccess,
          onChanged: (bool? value) {
            if (value != null) {
              relay.relayStatus.readAccess = value;
              setState(() {});
              relayProvider.saveRelay();
            }
          },
        ),
      ));
    }

    if (relay is RelayLocal) {
      list.add(Container(
        child: CheckboxListTile(
          title: Text(s.Data_Sync_Mode),
          value: dataSyncMode,
          onChanged: (bool? value) {
            if (value != null) {
              dataSyncMode = value;
              setState(() {});
            }
          },
        ),
      ));

      list.add(GestureDetector(
        onTap: backMyNotes,
        child: ListTile(
          title: Text(s.Backup_my_notes),
          mouseCursor: SystemMouseCursors.click,
        ),
      ));

      list.add(GestureDetector(
        onTap: importNotes,
        child: ListTile(
          title: Text(s.Import_notes),
          mouseCursor: SystemMouseCursors.click,
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: themeData.appBarTheme.titleTextStyle!.color,
          ),
        ),
        title: Text(
          s.Relay_Info,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.maxFinite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: list,
          ),
        ),
      ),
    );
  }

  void backMyNotes() async {
    var eventDatas = await relayLocalDB!.queryEventByPubkey(nostr!.publicKey);
    var jsonStr = jsonEncode(eventDatas);
    var result = await FileSaver.instance.saveFile(
      name: DateTime.now().millisecondsSinceEpoch.toString(),
      bytes: utf8.encode(jsonStr),
      ext: ".json",
    );

    BotToast.showText(text: "${S.of(context).File_save_success}: $result");
  }

  Future<void> importNotes() async {
    var result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      allowedExtensions: ["json"],
      withData: true,
    );
    if (result != null) {
      var cancelFunc = BotToast.showLoading();
      try {
        var platformFile = result.files.first;
        var jsonObj = jsonDecode(utf8.decode(platformFile.bytes!));
        if (jsonObj is List) {
          for (var eventJson in jsonObj) {
            var event = Event.fromJson(eventJson);
            nostr!.broadcase(event);
            // await Future.delayed(const Duration(milliseconds: 10));
          }
        }
      } finally {
        cancelFunc.call();
      }
    }
  }
}

class RelayInfoItemComponent extends StatelessWidget {
  String title;

  Widget child;

  RelayInfoItemComponent({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> list = [];

    list.add(Container(
      child: Text(
        "$title :",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    list.add(Container(
      padding: EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: child,
    ));

    return Container(
      padding: EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      margin: EdgeInsets.only(
        bottom: Base.BASE_PADDING,
      ),
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }
}

class NipComponent extends StatelessWidget {
  dynamic nip;

  NipComponent({required this.nip});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;

    var nipStr = nip.toString();
    if (nipStr == "1") {
      nipStr = "01";
    } else if (nipStr == "2") {
      nipStr = "02";
    } else if (nipStr == "3") {
      nipStr = "03";
    } else if (nipStr == "4") {
      nipStr = "04";
    } else if (nipStr == "5") {
      nipStr = "05";
    } else if (nipStr == "6") {
      nipStr = "06";
    } else if (nipStr == "7") {
      nipStr = "07";
    } else if (nipStr == "8") {
      nipStr = "08";
    } else if (nipStr == "9") {
      nipStr = "09";
    }

    return GestureDetector(
      onTap: () {
        var url =
            "https://github.com/nostr-protocol/nips/blob/master/$nipStr.md";
        WebViewRouter.open(context, url);
      },
      child: Text(
        nipStr,
        style: TextStyle(
          color: mainColor,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
