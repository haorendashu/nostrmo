import 'package:flutter/material.dart';

import '../client/event.dart';

class EventDeleteCallback extends InheritedWidget {
  Function(Event) onDeleteCallback;

  EventDeleteCallback({
    super.key,
    required super.child,
    required this.onDeleteCallback,
  });

  static EventDeleteCallback? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EventDeleteCallback>();
  }

  @override
  bool updateShouldNotify(covariant EventDeleteCallback oldWidget) {
    return false;
  }

  void onDelete(Event event) {
    onDeleteCallback(event);
  }
}
