import 'package:flutter/material.dart';

import '../provider/pc_router_fake_provider.dart';

class PcRouterFake extends InheritedWidget {
  RouterFakeInfo info;

  PcRouterFake({
    super.key,
    required super.child,
    required this.info,
  });

  static PcRouterFake? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PcRouterFake>();
  }

  @override
  bool updateShouldNotify(covariant PcRouterFake oldWidget) {
    return false;
  }
}
