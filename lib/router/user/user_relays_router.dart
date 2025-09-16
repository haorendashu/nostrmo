import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/relay/relay_metadata.dart';
import 'package:nostr_sdk/relay/relay_status.dart';
import 'package:nostr_sdk/utils/relay_addr_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:nostrmo/router/relays/relay_speed_component.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';

class UserRelayRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _UserRelayRouter();
  }
}

class _UserRelayRouter extends State<UserRelayRouter> {
  List<RelayMetadata>? relays;
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    var s = S.of(context);
    if (relays == null) {
      relays = [];
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is List<dynamic>) {
        for (var tag in arg as List<dynamic>) {
          if (tag is List<dynamic>) {
            var length = tag.length;
            bool write = true;
            bool read = true;
            if (length > 1) {
              var name = tag[0];
              var value = tag[1];
              if (name == "r") {
                if (length > 2) {
                  var operType = tag[2];
                  if (operType == "read") {
                    write = false;
                  } else if (operType == "write") {
                    read = false;
                  }
                }

                relays!.add(RelayMetadata(value, read, write));
              }
            }
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(s.Relays),
      ),
      body: Container(
        margin: const EdgeInsets.only(
          top: Base.BASE_PADDING,
        ),
        child: ListView.builder(
          itemBuilder: (context, index) {
            var relayMetadata = relays![index];
            return Selector<RelayProvider, RelayStatus?>(
                builder: (context, relayStatus, child) {
              return RelayMetadataComponent(
                relayMetadata: relayMetadata,
                addAble: relayStatus == null,
              );
            }, selector: (context, _provider) {
              return _provider.getNormalOrCacheRelayStatus(relayMetadata.addr);
            });
          },
          itemCount: relays!.length,
        ),
      ),
    );
  }
}

class RelayMetadataComponent extends StatelessWidget {
  RelayMetadata? relayMetadata;

  String? addr;

  bool addAble;

  RelayMetadataComponent({this.relayMetadata, this.addr, this.addAble = true})
      : assert(relayMetadata != null || addr != null);

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;
    var bodySmallFontSize = themeData.textTheme.bodySmall!.fontSize;

    String? relayAddr = addr;
    if (relayMetadata != null) {
      relayAddr = relayMetadata!.addr;
    }

    if (StringUtil.isBlank(relayAddr)) {
      return Container();
    }

    relayAddr = RelayAddrUtil.handle(relayAddr!);

    List<Widget> rightList = [];
    rightList.add(RelaySpeedComponent(relayAddr));
    Widget rightBtn = Row(
      children: rightList,
    );
    if (addAble) {
      rightList.add(GestureDetector(
        onTap: () {
          relayProvider.addRelay(relayAddr!);
        },
        child: Container(
          child: const Icon(
            Icons.add,
          ),
        ),
      ));
    }

    Widget bottomWidget = Container();
    if (relayMetadata != null) {
      bottomWidget = Row(
        children: [
          Container(
            margin: EdgeInsets.only(right: Base.BASE_PADDING),
            child: Text(
              s.Read,
              style: TextStyle(
                fontSize: bodySmallFontSize,
                color: relayMetadata!.read ? Colors.green : Colors.red,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: Base.BASE_PADDING),
            child: Text(
              s.Write,
              style: TextStyle(
                fontSize: bodySmallFontSize,
                color: relayMetadata!.write ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: Base.BASE_PADDING,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.only(
          top: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            left: BorderSide(
              width: 6,
              color: hintColor,
            ),
          ),
          // borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 2),
                    child: Text(relayAddr!),
                  ),
                  bottomWidget,
                ],
              ),
            ),
            rightBtn,
          ],
        ),
      ),
    );
  }
}
