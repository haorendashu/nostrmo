import 'package:flutter/material.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/nip58/badge_definition.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/badge_definition_provider.dart';
import 'package:nostrmo/provider/badge_provider.dart';
import 'package:provider/provider.dart';

import '../generated/l10n.dart';
import 'badge_detail_component.dart';

class BadgeAwardComponent extends StatefulWidget {
  Event event;

  BadgeAwardComponent({
    required this.event,
  });

  @override
  State<StatefulWidget> createState() {
    return _BadgeAwardComponent();
  }
}

class _BadgeAwardComponent extends State<BadgeAwardComponent> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var s = S.of(context);
    var badgeId = "";
    for (var tag in widget.event.tags) {
      if (tag is List && tag[0] == "a") {
        badgeId = tag[1];
      }
    }

    if (badgeId == "") {
      return Container();
    }

    var badgeDetailComp = Selector<BadgeDefinitionProvider, BadgeDefinition?>(
        builder: (context, badgeDefinition, child) {
      if (badgeDefinition == null) {
        return Container();
      }

      return BadgeDetailComponent(
        badgeDefinition: badgeDefinition,
      );
    }, selector: (context, _provider) {
      return _provider.get(badgeId, widget.event.pubkey);
    });

    List<Widget> list = [badgeDetailComp];

    var wearComp = Selector<BadgeProvider, bool>(
      builder: ((context, exist, child) {
        if (exist) {
          return Container();
        }

        return GestureDetector(
          onTap: () {
            String? source;
            if (widget.event.sources.isNotEmpty) {
              source = widget.event.sources[0];
            }
            badgeProvider.wear(badgeId, widget.event.id, relayAddr: source);
          },
          child: Container(
            margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            color: theme.primaryColor,
            width: double.infinity,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              s.Wear,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
      }),
      selector: ((context, badgeProvider) {
        return badgeProvider.containBadge(badgeId);
      }),
    );
    list.add(wearComp);

    return Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }
}
