import 'package:flutter/material.dart';

class RouterUtil {
  static Future<T?> router<T>(BuildContext context, String pageName,
      [Object? arguments]) async {
    return Navigator.of(context).pushNamed<T>(pageName, arguments: arguments);
  }

  static Object? routerArgs(BuildContext context) {
    RouteSettings? setting = ModalRoute.of(context)?.settings;
    if (setting != null) {
      return setting.arguments;
    }
    return null;
  }

  static void back(BuildContext context, [Object? returnObj]) {
    NavigatorState ns = Navigator.of(context);
    if (ns.canPop()) {
      ns.pop(returnObj);
    }
  }
}
