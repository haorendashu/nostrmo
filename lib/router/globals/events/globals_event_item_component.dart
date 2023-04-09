import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/component/event/event_main_component.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/single_event_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../../consts/base.dart';
import '../../../generated/l10n.dart';

@deprecated
class GlobalEventItemComponent extends StatefulWidget {
  String eventId;

  GlobalEventItemComponent({required this.eventId});

  @override
  State<StatefulWidget> createState() {
    return _GlobalEventItemComponent();
  }
}

class _GlobalEventItemComponent extends State<GlobalEventItemComponent> {
  ScreenshotController screenshotController = ScreenshotController();

  Event? _event;

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    return Selector<SingleEventProvider, Event?>(
      builder: (context, event, child) {
        if (event == null) {
          return Container(
            margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
            color: cardColor,
            height: 150,
            child: Center(
              child: Text(
                s.loading,
                style: TextStyle(
                  color: hintColor,
                ),
              ),
            ),
          );
        }
        _event = event;

        var main = Screenshot(
          child: Container(
            color: cardColor,
            margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
            padding: EdgeInsets.only(
              top: Base.BASE_PADDING,
              // bottom: Base.BASE_PADDING,
            ),
            child: EventMainComponent(
              screenshotController: screenshotController,
              event: _event!,
              pagePubkey: null,
              textOnTap: jumpToThread,
            ),
          ),
          controller: screenshotController,
        );

        return GestureDetector(
          onTap: jumpToThread,
          child: main,
        );
      },
      selector: (context, _provider) {
        return _provider.getEvent(widget.eventId);
      },
    );
  }

  void jumpToThread() {
    RouterUtil.router(context, RouterPath.THREAD_DETAIL, _event);
  }
}
