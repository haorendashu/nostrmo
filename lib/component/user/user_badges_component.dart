import 'package:flutter/material.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip58/badge_definition.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../main.dart';
import '../../provider/badge_definition_provider.dart';
import '../../util/later_function.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import '../badge_component.dart';
import '../badge_detail_dialog.dart';
import '../cust_state.dart';

class UserBadgesComponent extends StatefulWidget {
  String pubkey;

  UserBadgesComponent({super.key, required this.pubkey});

  @override
  State<StatefulWidget> createState() {
    return _UserBadgesComponent();
  }
}

class _UserBadgesComponent extends CustState<UserBadgesComponent>
    with LaterFunction {
  @override
  Widget doBuild(BuildContext context) {
    if (eventMemBox.isEmpty()) {
      return Container();
    }

    List<Widget> list = [];

    Map<dynamic, int> existMap = {};

    var events = eventMemBox.all();
    for (var event in events) {
      for (var tag in event.tags) {
        if (tag.length > 1) {
          if (tag[0] == "a") {
            var badgeId = tag[1];
            var itemWidget =
                Selector<BadgeDefinitionProvider, BadgeDefinition?>(
                    builder: (context, badgeDefinition, child) {
              if (badgeDefinition == null) {
                return Container();
              }

              if (existMap[badgeId] != null) {
                return Container();
              }
              existMap[badgeId] = 1;

              return GestureDetector(
                onTap: () {
                  BadgeDetailDialog.show(context, badgeDefinition);
                },
                child: Container(
                  margin: EdgeInsets.only(right: Base.BASE_PADDING_HALF),
                  child: BedgeComponent(
                    badgeDefinition: badgeDefinition,
                  ),
                ),
              );
            }, selector: (context, _provider) {
              return _provider.get(badgeId, event.pubkey);
            });

            list.add(itemWidget);
            break;
          }
        }
      }
    }

    return Container(
      padding: EdgeInsets.only(
        right: Base.BASE_PADDING,
        left: Base.BASE_PADDING,
      ),
      width: double.maxFinite,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: list,
        ),
      ),
    );
  }

  String subscribeId = StringUtil.rndNameStr(12);

  EventMemBox eventMemBox = EventMemBox(sortAfterAdd: false);

  @override
  Future<void> onReady(BuildContext context) async {
    var filter =
        Filter(authors: [widget.pubkey], kinds: [EventKind.BADGE_ACCEPT]);
    nostr!.query([filter.toJson()], (event) {
      var result = eventMemBox.add(event);
      if (result) {
        later(() {
          setState(() {});
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    nostr!.unsubscribe(subscribeId);
    disposeLater();
  }
}
