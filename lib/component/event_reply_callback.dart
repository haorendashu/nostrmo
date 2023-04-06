import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';

class EventReplyCallback extends InheritedWidget {
  Function(Event) onReplyCallback;

  EventReplyCallback({
    super.key,
    required super.child,
    required this.onReplyCallback,
  });

  static EventReplyCallback? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EventReplyCallback>();
  }

  @override
  bool updateShouldNotify(covariant EventReplyCallback oldWidget) {
    return false;
  }

  void onReply(Event event) {
    onReplyCallback(event);
  }
}
