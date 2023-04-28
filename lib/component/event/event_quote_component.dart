import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../client/event.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../provider/single_event_provider.dart';
import '../../util/router_util.dart';
import '../cust_state.dart';
import 'event_main_component.dart';

class EventQuoteComponent extends StatefulWidget {
  Event? event;

  String? id;

  bool showVideo;

  EventQuoteComponent({
    this.event,
    this.id,
    this.showVideo = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventQuoteComponent();
  }
}

class _EventQuoteComponent extends CustState<EventQuoteComponent> {
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var boxDecoration = BoxDecoration(
      color: cardColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          offset: const Offset(0, 0),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ],
    );

    if (widget.event != null) {
      return buildEventWidget(widget.event!, cardColor, boxDecoration);
    }

    return Selector<SingleEventProvider, Event?>(
      builder: (context, event, child) {
        if (event == null) {
          return buildBlankWidget(boxDecoration);
        }

        return buildEventWidget(event, cardColor, boxDecoration);
      },
      selector: (context, _provider) {
        return _provider.getEvent(widget.id!);
      },
    );
  }

  Widget buildEventWidget(
      Event event, Color cardColor, BoxDecoration boxDecoration) {
    return Screenshot(
      controller: screenshotController,
      child: Container(
        padding: const EdgeInsets.only(top: Base.BASE_PADDING),
        margin: const EdgeInsets.all(Base.BASE_PADDING),
        decoration: boxDecoration,
        child: GestureDetector(
          onTap: () {
            jumpToThread(event);
          },
          behavior: HitTestBehavior.translucent,
          child: EventMainComponent(
            screenshotController: screenshotController,
            event: event,
            showReplying: false,
            textOnTap: () {
              jumpToThread(event);
            },
            showVideo: widget.showVideo,
            imageListMode: true,
          ),
        ),
      ),
    );
  }

  Widget buildBlankWidget(BoxDecoration boxDecoration) {
    return Container(
      margin: const EdgeInsets.all(Base.BASE_PADDING),
      height: 60,
      decoration: boxDecoration,
      child: Center(child: Text(S.of(context).Note_loading)),
    );
  }

  void jumpToThread(Event event) {
    RouterUtil.router(context, RouterPath.THREAD_DETAIL, event);
  }

  @override
  Future<void> onReady(BuildContext context) async {}
}
