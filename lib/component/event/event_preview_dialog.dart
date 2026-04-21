import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostrmo/component/event/event_main_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:screenshot/screenshot.dart';

import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/table_mode_util.dart';

class EventPreviewDialog extends StatefulWidget {
  Event event;

  EventPreviewDialog({
    required this.event,
  });

  @override
  State<EventPreviewDialog> createState() => _EventPreviewDialog();

  static Future<bool?> show(BuildContext context, Event event) async {
    return await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (_context) {
        return EventPreviewDialog(
          event: event,
        );
      },
    );
  }
}

class _EventPreviewDialog extends State<EventPreviewDialog> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;
    var maxHeight = mediaDataCache.size.height;
    var textColor = themeData.textTheme.bodyMedium!.color;

    List<Widget> list = [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
        ),
        child: EventMainComponent(
          screenshotController: ScreenshotController(),
          event: widget.event,
        ),
      ),
      Container(
        margin: const EdgeInsets.only(
          // left: Base.BASE_PADDING_HALF,
          // right: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: Ink(
          decoration: BoxDecoration(color: mainColor),
          child: InkWell(
            onTap: () {
              RouterUtil.back(context);
            },
            highlightColor: mainColor.withOpacity(0.2),
            child: Container(
              color: mainColor,
              height: 40,
              alignment: Alignment.center,
              child: Text(
                "Back",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      )
    ];

    var main = Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight * 0.8,
        maxWidth: PlatformUtil.isPC() || TableModeUtil.isTableMode()
            ? mediaDataCache.size.width / 2
            : double.infinity,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: list,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
