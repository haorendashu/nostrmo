import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/event/event_main_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:screenshot/screenshot.dart';

class EventQuoteComponent extends StatefulWidget {
  Event? event;

  String? id;

  EventQuoteComponent({
    this.event,
    this.id,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventQuoteComponent();
  }
}

class _EventQuoteComponent extends CustState<EventQuoteComponent> {
  ScreenshotController screenshotController = ScreenshotController();
  Event? event;

  @override
  Widget doBuild(BuildContext context) {
    if (event == null && widget.event == null) {
      return Container();
    }
    event ??= widget.event;

    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    return Screenshot(
      controller: screenshotController,
      child: Container(
        padding: const EdgeInsets.only(top: Base.BASE_PADDING),
        margin: const EdgeInsets.all(Base.BASE_PADDING),
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 0),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: GestureDetector(
          onTap: jumpToThread,
          behavior: HitTestBehavior.translucent,
          child: EventMainComponent(
            screenshotController: screenshotController,
            event: event!,
            showReplying: false,
            textOnTap: jumpToThread,
          ),
        ),
      ),
    );
  }

  void jumpToThread() {
    RouterUtil.router(context, RouterPath.THREAD_DETAIL, widget.event);
  }

  @override
  Future<void> onReady(BuildContext context) async {
    if (widget.event == null && widget.id != null) {
      var filter = Filter(ids: [widget.id!]);
      nostr!.pool.query([filter.toJson()], (_event) {
        if (event == null) {
          setState(() {
            event = _event;
          });
        }
      });
    }
  }
}
