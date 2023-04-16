import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/component/comfirm_dialog.dart';
import 'package:nostrmo/util/when_stop_function.dart';
import 'package:provider/provider.dart';

import '../../client/event_kind.dart' as kind;
import '../../client/filter.dart';
import '../../component/cust_state.dart';
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

class _RelaysRouter extends CustState<RelaysRouter> with WhenStopFunction {
  TextEditingController controller = TextEditingController();
  @override
  Widget doBuild(BuildContext context) {
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

  Event? remoteRelayEvent;

  @override
  Future<void> onReady(BuildContext context) async {
    var filter = Filter(
        authors: [nostr!.publicKey],
        limit: 1,
        kinds: [kind.EventKind.RELAY_LIST_METADATA]);
    nostr!.pool.query([filter.toJson()], (event) {
      if ((remoteRelayEvent != null &&
              event.createdAt > remoteRelayEvent!.createdAt) ||
          remoteRelayEvent == null) {
        setState(() {
          remoteRelayEvent = event;
        });
        whenStop(handleRemoteRelays);
      }
    });
  }

  Future<void> handleRemoteRelays() async {
    var relaysUpdatedTime = relayProvider.updatedTime();
    if (remoteRelayEvent != null &&
        (relaysUpdatedTime == null ||
            remoteRelayEvent!.createdAt - relaysUpdatedTime > 60 * 5)) {
      var result = await ComfirmDialog.show(context,
          S.of(context).Find_clouded_relay_list_do_you_want_to_download);
      if (result) {
        List<String> list = [];
        for (var tag in remoteRelayEvent!.tags) {
          if (tag.length > 1) {
            var key = tag[0];
            var value = tag[1];
            if (key == "r") {
              list.add(value);
            }
          }
        }
        relayProvider.setRelayListAndUpdate(list);
      }
    }
  }
}
