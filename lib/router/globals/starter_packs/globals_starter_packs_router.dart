import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/nip19/nip19_tlv.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/event/event_main_component.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../../component/keep_alive_cust_state.dart';
import '../../../component/placeholder/event_list_placeholder.dart';
import '../../../consts/base.dart';
import '../../../main.dart';
import '../../../provider/replaceable_event_provider.dart';
import '../../../provider/setting_provider.dart';
import '../../../util/dio_util.dart';
import '../../../util/table_mode_util.dart';

class GlobalsStarterPacksRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GlobalsStarterPacksRouter();
  }
}

class _GlobalsStarterPacksRouter
    extends KeepAliveCustState<GlobalsStarterPacksRouter>
    with PenddingEventsLaterFunction {
  ScrollController scrollController = ScrollController();

  EventMemBox eventBox = EventMemBox(sortAfterAdd: false);

  List<Naddr> naddrs = [];

  @override
  Widget doBuild(BuildContext context) {
    var _settingProvider = Provider.of<SettingProvider>(context);
    if (naddrs.isEmpty) {
      return EventListPlaceholder(
        onRefresh: refresh,
      );
    }

    var main = ListView.builder(
      controller: scrollController,
      itemBuilder: (context, index) {
        var naddr = naddrs[index];
        if (StringUtil.isBlank(naddr.author) || StringUtil.isBlank(naddr.id)) {
          return Container();
        }

        var aid = AId(kind: naddr.kind, pubkey: naddr.author, title: naddr.id);

        return Selector<ReplaceableEventProvider, Event?>(
          builder: (context, event, child) {
            if (event == null) {
              return Container();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: Base.BASE_PADDING),
              child: EventMainComponent(
                screenshotController: ScreenshotController(),
                event: event,
              ),
            );
          },
          selector: (context, _provider) {
            return _provider.getEvent(aid, relays: naddr.relays);
          },
        );
      },
      itemCount: naddrs.length,
    );

    if (TableModeUtil.isTableMode()) {
      return GestureDetector(
        onVerticalDragUpdate: (detail) {
          scrollController.jumpTo(scrollController.offset - detail.delta.dy);
        },
        behavior: HitTestBehavior.translucent,
        child: main,
      );
    }
    return main;
  }

  Future<void> refresh() async {
    var str = await DioUtil.getStr(Base.INDEXS_STARTER_PACKS);
    print(str);
    if (StringUtil.isNotBlank(str)) {
      naddrs.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        if (itf is String) {
          var naddr = NIP19Tlv.decodeNaddr(itf);
          if (naddr != null) {
            naddrs.add(naddr);
          }
        }
      }

      naddrs.shuffle();
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();
  }

  @override
  Future<void> onReady(BuildContext context) async {
    indexProvider.setEventScrollController(scrollController);
    refresh();
  }
}
