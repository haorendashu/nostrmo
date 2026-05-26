import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/relay/relay_status.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostrmo/component/confirm_dialog.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostr_sdk/utils/when_stop_function.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/cust_state.dart';
import '../../consts/base.dart';
import '../../consts/client_connected.dart';
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

  TextEditingController searchController = TextEditingController();

  FocusNode searchFocusNode = FocusNode();

  String relaySearchText = "";

  bool showSearchInput = false;

  int relayType = RelayType.NORMAL;

  @override
  Widget doBuild(BuildContext context) {
    var s = S.of(context);
    var _relayProvider = Provider.of<RelayProvider>(context);
    var relayStatusLocal = _relayProvider.relayStatusLocal;
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var normalRelayStatuses =
        _filterRelayStatuses(_relayProvider.getNormalRelayStatus());
    var cacheRelayStatuses =
        _filterRelayStatuses(_relayProvider.getCacheRelayStatus());
    var indexRelayStatuses =
        _filterRelayStatuses(_relayProvider.getIndexRelayStatus());
    var allTempRelayStatuses = _relayProvider.getTempRelayStatus();
    var tempRelayStatuses = _filterRelayStatuses(allTempRelayStatuses);
    var tempRelayConnectedNum = allTempRelayStatuses
        .where((status) => status.connected == ClientConneccted.CONNECTED)
        .length;

    List<Widget> list = [];

    if (relayStatusLocal != null && _matchRelayAddr(relayStatusLocal.addr)) {
      list.add(RelaysItemComponent(
        addr: relayStatusLocal.addr,
        relayStatus: relayStatusLocal,
        editable: false,
      ));
    }

    if (normalRelayStatuses.isNotEmpty) {
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
            ),
          ],
        ),
      ));
    }
    for (var i = 0; i < normalRelayStatuses.length; i++) {
      var relayStatus = normalRelayStatuses[i];
      var addr = relayStatus.addr;

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

    if (indexRelayStatuses.isNotEmpty) {
      list.add(Container(
        padding: EdgeInsets.only(
          left: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: Text(
          s.Index_Relay,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      for (var i = 0; i < indexRelayStatuses.length; i++) {
        var relayStatus = indexRelayStatuses[i];
        var addr = relayStatus.addr;

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
    }

    if (cacheRelayStatuses.isNotEmpty) {
      list.add(Container(
        padding: EdgeInsets.only(
          left: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: Text(
          s.Cache_Relay,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      for (var i = 0; i < cacheRelayStatuses.length; i++) {
        var relayStatus = cacheRelayStatuses[i];
        var addr = relayStatus.addr;

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
    }

    if (tempRelayStatuses.isNotEmpty) {
      list.add(Container(
        padding: EdgeInsets.only(
          left: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: Text(
          "${s.TempRelays} （ $tempRelayConnectedNum / ${allTempRelayStatuses.length} ）",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));
      for (var i = 0; i < tempRelayStatuses.length; i++) {
        var relayStatus = tempRelayStatuses[i];

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
              setState(() {
                showSearchInput = true;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  searchFocusNode.requestFocus();
                }
              });
            },
            child: Container(
              padding: EdgeInsets.only(right: Base.BASE_PADDING),
              child: Icon(
                Icons.search,
                color: themeData.appBarTheme.titleTextStyle!.color,
              ),
            ),
          ),
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
            child: Column(
              children: [
                if (showSearchInput)
                  Container(
                    padding: const EdgeInsets.only(
                      left: Base.BASE_PADDING,
                      right: Base.BASE_PADDING,
                      bottom: Base.BASE_PADDING,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            focusNode: searchFocusNode,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: s.Please_input_search_content,
                              prefixIcon: const Icon(Icons.search),
                            ),
                            onChanged: (v) {
                              setState(() {
                                relaySearchText = v.trim();
                              });
                            },
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            searchFocusNode.unfocus();
                            searchController.clear();
                            setState(() {
                              relaySearchText = "";
                              showSearchInput = false;
                            });
                          },
                          child: Text(s.Cancel),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView(
                    children: list,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          child: Row(children: [
            Container(
              padding: EdgeInsets.only(left: Base.BASE_PADDING),
              child: const Icon(Icons.cloud),
            ),
            Container(
              child: DropdownButton(
                underline: Container(
                  height: 0,
                ),
                value: relayType,
                padding: const EdgeInsets.only(
                    left: Base.BASE_PADDING, right: Base.BASE_PADDING_HALF),
                items: [
                  DropdownMenuItem(
                    value: RelayType.NORMAL,
                    child: Text(s.Normal),
                  ),
                  DropdownMenuItem(
                    value: RelayType.INDEX,
                    child: Text(s.Index),
                  ),
                  DropdownMenuItem(
                    value: RelayType.CACHE,
                    child: Text(s.Cache),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      relayType = v;
                    });
                  }
                },
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: s.Input_relay_address,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: addRelay,
                  ),
                ),
              ),
            ),
          ]),
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

    relayProvider.addRelay(addr, relayType: relayType);
    controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Future<void> onReady(BuildContext context) async {}

  @override
  void dispose() {
    controller.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  bool _matchRelayAddr(String addr) {
    if (StringUtil.isBlank(relaySearchText)) {
      return true;
    }

    return addr.toLowerCase().contains(relaySearchText.toLowerCase());
  }

  List<RelayStatus> _filterRelayStatuses(List<RelayStatus> statuses) {
    if (StringUtil.isBlank(relaySearchText)) {
      return statuses;
    }

    return statuses.where((status) => _matchRelayAddr(status.addr)).toList();
  }

  void testAllMyRelaysSpeed() {
    var relayStatuses = relayProvider.getNormalRelayStatus();
    for (var i = 0; i < relayStatuses.length; i++) {
      var relayStatus = relayStatuses[i];
      urlSpeedProvider.testSpeed(relayStatus.addr);
    }
  }
}
