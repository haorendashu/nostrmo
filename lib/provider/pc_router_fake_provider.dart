import 'dart:async';

import 'package:flutter/material.dart';

class PcRouterFakeProvider extends ChangeNotifier {
  static int MAX_STACK_NUM = 20;

  List<RouterFakeInfo> routerFakeInfos = [];

  void router<T>(
    RouterFakeInfo routerFakeInfo, {
    bool clear = false,
  }) {
    List<RouterFakeInfo> newList = [];
    var oldLength = routerFakeInfos.length;

    if (!clear) {
      if (oldLength < MAX_STACK_NUM - 1) {
        newList.addAll(routerFakeInfos);
      } else {
        for (var i = 1; i < oldLength; i++) {
          newList.add(routerFakeInfos[i]);
        }
      }
    }

    newList.add(routerFakeInfo);

    routerFakeInfos = newList;
    notifyListeners();
  }

  void remove(RouterFakeInfo info) {
    List<RouterFakeInfo> newList = [];
    routerFakeInfos.remove(info);
    newList.addAll(routerFakeInfos);
    routerFakeInfos = newList;
    notifyListeners();
  }
}

class RouterFakeInfo<T> {
  String? routerPath;

  Object? arguments;

  final Completer<T> completer = Completer<T>();

  Widget Function(BuildContext)? buildContent;

  RouterFakeInfo({
    this.routerPath,
    this.arguments,
    this.buildContent,
  });
}
