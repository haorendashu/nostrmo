import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:provider/provider.dart';

import '../../client/nip19/nip19.dart';
import '../../component/cust_state.dart';
import '../../client/event_kind.dart' as kind;
import '../../client/filter.dart';
import '../../component/event/event_list_component.dart';
import '../../component/event_delete_callback.dart';
import '../../consts/base_consts.dart';
import '../../consts/router_path.dart';
import '../../data/event_mem_box.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/setting_provider.dart';
import '../../util/load_more_event.dart';
import '../../util/peddingevents_later_function.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';

class SearchRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SearchRouter();
  }
}

class _SearchRouter extends CustState<SearchRouter>
    with PenddingEventsLaterFunction, LoadMoreEvent {
  TextEditingController controller = TextEditingController();

  ScrollController scrollController = ScrollController();

  @override
  Future<void> onReady(BuildContext context) async {
    // scrollController.addListener(() {
    //   var maxScrollExtent = scrollController.position.maxScrollExtent;
    //   var offset = scrollController.offset;

    //   var leftNum = (1 - (offset / maxScrollExtent)) * itemLength;
    //   print("itemLength $itemLength leftNum $leftNum");
    //   if (leftNum < loadMoreItemLeftNum) {
    //     loadMore();
    //   }
    // });
    bindLoadMoreScroll(scrollController);
  }

  @override
  Widget doBuild(BuildContext context) {
    var s = S.of(context);
    var _settingProvider = Provider.of<SettingProvider>(context);
    var events = eventMemBox.all();
    preBuild();

    return Scaffold(
      body: EventDeleteCallback(
        onDeleteCallback: onDeletedCallback,
        child: Container(
          child: Column(children: [
            Container(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "npub ${s.or} hex",
                ),
                onEditingComplete: onEditingComplete,
              ),
            ),
            Expanded(
                child: Container(
              child: ListView.builder(
                controller: scrollController,
                itemBuilder: (BuildContext context, int index) {
                  var event = events[index];

                  return EventListComponent(
                    event: event,
                    showVideo:
                        _settingProvider.videoPreviewInList == OpenStatus.OPEN,
                  );
                },
                itemCount: itemLength,
              ),
            )),
          ]),
        ),
      ),
    );
  }

  String? subscribeId;

  EventMemBox eventMemBox = EventMemBox();

  Filter? filter;

  @override
  void doQuery() {
    preQuery();

    if (subscribeId != null) {
      unSubscribe();
    }
    subscribeId = generatePrivateKey();

    filter!.until = until;
    nostr!.pool.query([filter!.toJson()], (event) {
      later(event, (list) {
        var addResult = eventMemBox.addList(list);
        if (addResult) {
          setState(() {});
        }
      }, null);
    }, subscribeId);
  }

  void unSubscribe() {
    nostr!.pool.unsubscribe(subscribeId!);
    subscribeId = null;
  }

  void onEditingComplete() {
    hideKeyBoard();

    var value = controller.text;
    value = value.trim();
    if (StringUtil.isBlank(value)) {
      BotToast.showText(text: S.of(context).Empty_text_may_be_ban_by_relays);
    }

    List<String>? authors;
    if (StringUtil.isNotBlank(value) && value.indexOf("npub") == 0) {
      try {
        var result = Nip19.decode(value);
        authors = [result];
      } catch (e) {
        log(e.toString());
        // TODO handle error
        return;
      }
    } else {
      authors = [value];
    }

    eventMemBox = EventMemBox();
    until = null;
    filter = Filter(
        kinds: [kind.EventKind.TEXT_NOTE, kind.EventKind.REPOST],
        authors: authors,
        limit: queryLimit);
    penddingEvents.clear;
    doQuery();
  }

  void hideKeyBoard() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  EventMemBox getEventBox() {
    return eventMemBox;
  }

  @override
  void dispose() {
    super.dispose();
    disposeLater();
  }

  onDeletedCallback(Event event) {
    eventMemBox.delete(event.id);
    setState(() {});
  }
}
