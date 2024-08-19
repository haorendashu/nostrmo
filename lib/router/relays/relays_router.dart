import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/relay/relay_status.dart';
import 'package:nostrmo/component/confirm_dialog.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/when_stop_function.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/relay_provider.dart';
import '../../util/router_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
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
    var relayStatusLocal = _relayProvider.relayStatusLocal;
    var relayStatusMap = _relayProvider.relayStatusMap;
    var themeData = Theme.of(context);
    var color = themeData.textTheme.bodyLarge!.color;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];

    if (relayStatusLocal != null) {
      list.add(RelaysItemComponent(
        addr: relayStatusLocal.addr,
        relayStatus: relayStatusLocal,
        editable: false,
      ));
    }

    list.add(Container(
      padding: EdgeInsets.only(
        left: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING_HALF,
      ),
      child: Row(
        children: [
          Text(
            s.MyRelays,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: testAllMyRelaysSpeed,
            child: Container(
              margin: EdgeInsets.only(left: Base.BASE_PADDING),
              child: Icon(Icons.speed),
            ),
          )
        ],
      ),
    ));
    for (var i = 0; i < relayAddrs.length; i++) {
      var addr = relayAddrs[i];
      var relayStatus = relayStatusMap[addr];
      relayStatus ??= RelayStatus(addr);

      var rwText = "W R";
      if (relayStatus.readAccess && !relayStatus.writeAccess) {
        rwText = "R";
      } else if (!relayStatus.readAccess && relayStatus.writeAccess) {
        rwText = "W";
      }

      list.add(RelaysItemComponent(
        addr: addr,
        relayStatus: relayStatus,
        rwText: rwText,
      ));
    }

    var tempRelayStatus = _relayProvider.tempRelayStatus();
    if (tempRelayStatus.isNotEmpty) {
      list.add(Container(
        padding: EdgeInsets.only(
          left: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: Text(
          s.TempRelays,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
      for (var i = 0; i < tempRelayStatus.length; i++) {
        var relayStatus = tempRelayStatus[i];

        var rwText = "W R";
        if (relayStatus.readAccess && !relayStatus.writeAccess) {
          rwText = "R";
        } else if (!relayStatus.readAccess && relayStatus.writeAccess) {
          rwText = "W";
        }

        list.add(RelaysItemComponent(
          addr: relayStatus.addr,
          relayStatus: relayStatus,
          rwText: rwText,
          editable: false,
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          s.Relays,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              RouterUtil.router(context, RouterPath.RELAYHUB);
            },
            child: Container(
              padding: EdgeInsets.only(right: Base.BASE_PADDING),
              child: Icon(
                Icons.cloud,
                color: themeData.appBarTheme.titleTextStyle!.color,
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(
              top: Base.BASE_PADDING,
            ),
            child: ListView(
              children: list,
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

  // Event? remoteRelayEvent;

  @override
  Future<void> onReady(BuildContext context) async {
    // var filter = Filter(
    //     authors: [nostr!.publicKey],
    //     limit: 1,
    //     kinds: [kind.EventKind.RELAY_LIST_METADATA]);
    // nostr!.query([filter.toJson()], (event) {
    //   if ((remoteRelayEvent != null &&
    //           event.createdAt > remoteRelayEvent!.createdAt) ||
    //       remoteRelayEvent == null) {
    //     setState(() {
    //       remoteRelayEvent = event;
    //     });
    //     whenStop(handleRemoteRelays);
    //   }
    // });
  }

  // Future<void> handleRemoteRelays() async {
  // var relaysUpdatedTime = relayProvider.updatedTime();
  // if (remoteRelayEvent != null &&
  //     (relaysUpdatedTime == null ||
  //         remoteRelayEvent!.createdAt - relaysUpdatedTime > 60 * 5)) {
  //   var result = await ConfirmDialog.show(context,
  //       S.of(context).Find_clouded_relay_list_do_you_want_to_download);
  //   if (result == true) {
  //     List<String> list = [];
  //     for (var tag in remoteRelayEvent!.tags) {
  //       if (tag.length > 1) {
  //         var key = tag[0];
  //         var value = tag[1];
  //         if (key == "r") {
  //           list.add(value);
  //         }
  //       }
  //     }
  //     relayProvider.setRelayListAndUpdate(list);
  //   }
  // }
  // }

  void testAllMyRelaysSpeed() {
    var relayAddrs = relayProvider.relayAddrs;
    for (var i = 0; i < relayAddrs.length; i++) {
      var relayAddr = relayAddrs[i];
      urlSpeedProvider.testSpeed(relayAddr);
    }
  }
}
