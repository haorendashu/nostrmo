import 'package:flutter/material.dart';
import 'package:nostrmo/component/comfirm_dialog.dart';
import 'package:nostrmo/data/relay_status.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import 'content_str_link_component.dart';

class ContentRelayComponent extends StatelessWidget {
  String addr;

  ContentRelayComponent(this.addr);

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    Color? cardColor = themeData.cardColor;
    if (cardColor == Colors.white) {
      cardColor = Colors.grey[300];
    }
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;

    return Selector<RelayProvider, RelayStatus?>(
        builder: (context, relayStatus, client) {
      List<Widget> list = [
        Icon(
          Icons.cloud,
          size: fontSize,
        ),
        Container(
          margin: const EdgeInsets.only(
            left: 6,
            right: 4,
          ),
          child: Text(addr),
        )
      ];
      if (relayStatus == null) {
        list.add(Icon(
          Icons.add,
          size: fontSize,
        ));
      }

      Widget main = Container(
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING_HALF,
          right: Base.BASE_PADDING_HALF,
          top: 2,
          bottom: 2,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: list,
        ),
      );

      if (relayStatus == null) {
        main = GestureDetector(
          onTap: () async {
            var result = await ComfirmDialog.show(
                context, S.of(context).Add_this_relay_to_local);
            if (result == true) {
              relayProvider.addRelay(addr);
            }
          },
          child: main,
        );
      }

      return main;
    }, selector: (context, _provider) {
      return _provider.getRelayStatus(addr);
    });
  }
}
