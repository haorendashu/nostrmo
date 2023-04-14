import 'package:flutter/material.dart';
import 'package:nostrmo/data/relay_status.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:provider/provider.dart';

import '../../client/relay_metadata.dart';
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
              return _provider.getRelayStatus(relayMetadata.addr);
            });
          },
          itemCount: relays!.length,
        ),
      ),
    );
  }
}

class RelayMetadataComponent extends StatelessWidget {
  RelayMetadata relayMetadata;

  bool addAble;

  RelayMetadataComponent({required this.relayMetadata, this.addAble = true});

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;
    var bodySmallFontSize = themeData.textTheme.bodySmall!.fontSize;

    Widget rightBtn = Container();
    if (addAble) {
      rightBtn = GestureDetector(
        onTap: () {
          relayProvider.addRelay(relayMetadata.addr);
        },
        child: Container(
          child: const Icon(
            Icons.add,
          ),
        ),
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
                    child: Text(relayMetadata.addr),
                  ),
                  Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: Base.BASE_PADDING),
                        child: Text(
                          s.Read,
                          style: TextStyle(
                            fontSize: bodySmallFontSize,
                            color:
                                relayMetadata.read ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(right: Base.BASE_PADDING),
                        child: Text(
                          s.Write,
                          style: TextStyle(
                            fontSize: bodySmallFontSize,
                            color:
                                relayMetadata.write ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
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
