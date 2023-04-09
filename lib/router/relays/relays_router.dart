import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/relay_status.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/relay_provider.dart';
import '../../util/string_util.dart';
import 'relays_item_component.dart';

class RelaysRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RelaysRouter();
  }
}

class _RelaysRouter extends State<RelaysRouter> {
  TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var _relayProvider = Provider.of<RelayProvider>(context);
    var relayAddrs = _relayProvider.relayAddrs;
    var relayStatusMap = relayProvider.relayStatusMap;
    var themeData = Theme.of(context);
    var color = themeData.textTheme.bodyLarge!.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.Relays),
      ),
      body: Column(children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.only(
              top: Base.BASE_PADDING,
            ),
            child: ListView.builder(
              itemBuilder: (context, index) {
                var addr = relayAddrs[index];
                var relayStatus = relayStatusMap[addr];
                relayStatus ??= RelayStatus(addr);

                return RelaysItemComponent(
                  addr: addr,
                  relayStatus: relayStatus,
                );
              },
              itemCount: relayAddrs.length,
            ),
          ),
        ),
        Container(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.cloud),
              hintText: s.Input_relay_address,
              suffixIcon: IconButton(
                icon: Icon(Icons.add),
                onPressed: addRelay,
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void addRelay() {
    var addr = controller.text;
    addr = addr.trim();
    if (StringUtil.isBlank(addr)) {
      BotToast.showText(text: S.of(context).Address_can_t_be_null);
      return;
    }

    relayProvider.addRelay(addr);
    controller.clear();
    FocusScope.of(context).unfocus();
  }
}
