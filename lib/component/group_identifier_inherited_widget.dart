import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip29/group_identifier.dart';

class GroupIdentifierInheritedWidget extends InheritedWidget {
  GroupIdentifier groupIdentifier;

  GroupIdentifierInheritedWidget({
    super.key,
    required super.child,
    required this.groupIdentifier,
  });

  static GroupIdentifierInheritedWidget? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GroupIdentifierInheritedWidget>();
  }

  static GroupIdentifier? getGroupIdentifier(BuildContext context) {
    var inheritedWidget = of(context);
    if (inheritedWidget != null) {
      return inheritedWidget.groupIdentifier;
    }

    return null;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
