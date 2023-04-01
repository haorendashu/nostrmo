import 'package:flutter/material.dart';
import 'package:nostrmo/client/cust_relay.dart';
import 'package:nostrmo/data/relay_status.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:provider/provider.dart';

import 'relays_item_component.dart';

class RelaysRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RelaysRouter();
  }
}

class _RelaysRouter extends State<RelaysRouter> {
  @override
  Widget build(BuildContext context) {
    var _relayProvider = Provider.of<RelayProvider>(context);
    var relayAddrs = _relayProvider.relayAddrs;
    var relayStatusMap = relayProvider.relayStatusMap;

    return Scaffold(
      appBar: AppBar(
        title: Text("Relays"),
      ),
      body: Container(
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
    );
  }
}
