import 'package:flutter/material.dart';
import 'package:nostrmo/provider/single_event_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../consts/router_path.dart';
import '../../generated/l10n.dart';

class EventIdRouterComponent extends StatefulWidget {
  String eventId;

  String? relayAddr;

  EventIdRouterComponent(this.eventId, this.relayAddr);

  static Future<void> router(
    BuildContext context,
    String eventId, {
    String? relayAddr,
  }) async {
    var event = await showDialog(
      context: context,
      builder: (context) {
        return EventIdRouterComponent(eventId, relayAddr);
      },
    );

    if (event != null) {
      RouterUtil.router(context, RouterPath.getThreadDetailPath(), event);
    }
  }

  @override
  State<StatefulWidget> createState() {
    return _EventIdRouterComponent();
  }
}

class _EventIdRouterComponent extends State<EventIdRouterComponent> {
  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var _singleEventProvider = Provider.of<SingleEventProvider>(context);
    var event = _singleEventProvider.getEvent(widget.eventId,
        eventRelayAddr: widget.relayAddr);
    if (event != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RouterUtil.back(context, event);
      });
    } else {}

    return Scaffold(
      appBar: AppBar(
        title: Text(s.loading),
      ),
      body: Center(
        child: Text(s.Note_loading),
      ),
    );
  }
}
