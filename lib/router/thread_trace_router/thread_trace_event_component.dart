import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:screenshot/screenshot.dart';

import '../../component/event/event_main_component.dart';

class ThreadTraceEventComponent extends StatefulWidget {
  Event event;

  Function? textOnTap;

  bool traceMode;

  ThreadTraceEventComponent(
    this.event, {
    super.key,
    this.textOnTap,
    this.traceMode = true,
  });

  @override
  State<StatefulWidget> createState() {
    return _ThreadTraceEventComponent();
  }
}

class _ThreadTraceEventComponent extends State<ThreadTraceEventComponent> {
  ScreenshotController ssController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: ssController,
      child: EventMainComponent(
        screenshotController: ssController,
        event: widget.event,
        showReplying: false,
        showVideo: true,
        imageListMode: false,
        showSubject: false,
        showLinkedLongForm: false,
        traceMode: widget.traceMode,
        showLongContent: true,
        textOnTap: () {
          if (widget.textOnTap != null) {
            widget.textOnTap!();
          }
        },
      ),
    );
  }
}
