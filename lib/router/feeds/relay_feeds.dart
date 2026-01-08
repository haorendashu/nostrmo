import 'package:flutter/material.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/placeholder/event_list_placeholder.dart';
import 'package:nostrmo/consts/event_kind_type.dart';
import 'package:nostrmo/main.dart';

class RelayFeeds extends StatefulWidget {
  List<String> relayAddr;

  RelayFeeds(this.relayAddr, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _RelayFeeds();
  }
}

class _RelayFeeds extends CustState<RelayFeeds> {
  late int _since;

  late int _until;

  @override
  void initState() {
    super.initState();
    _until = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _since = _until - const Duration(hours: 2).inSeconds;
  }

  EventMemBox eventBox = EventMemBox();

  void queryOnComplete() {
    var length = eventBox.length();
    if (length < 100) {
      // too less, need pull more data.
      var oldUntil = _until;
      var newUntil = oldUntil - (_since - _until) * 2;
      _until = newUntil;
      load(oldUntil, newUntil);
    }
  }

  void load(int since, int until) {
    var filter = Filter(
        kinds: EventKindType.SUPPORTED_EVENTS, since: since, until: until);
    nostr!.query([filter.toJson()], (e) {
      var newEvent = eventBox.add(e);
      if (newEvent) {
        setState(() {});
      }
    }, onComplete: queryOnComplete, targetRelays: widget.relayAddr);
  }

  @override
  Future<void> onReady(BuildContext context) async {
    load(_since, _until);
  }

  @override
  Widget doBuild(BuildContext context) {
    if (eventBox.isEmpty()) {
      return EventListPlaceholder();
    }
    return Container();
  }
}
