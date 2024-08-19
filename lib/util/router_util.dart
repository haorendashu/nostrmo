import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostrmo/component/pc_router_fake.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/table_mode_util.dart';

import '../provider/pc_router_fake_provider.dart';

class RouterUtil {
  static Future<T?> router<T>(BuildContext context, String pageName,
      [Object? arguments]) async {
    if (!TableModeUtil.isTableMode()) {
      return Navigator.of(context).pushNamed<T>(pageName, arguments: arguments);
    } else {
      bool clear = false;
      var parentRouterFake = PcRouterFake.of(context);
      if (parentRouterFake == null) {
        // means this request is from home, globals, search or dms, just to clean stack and push
        clear = true;
      }
      var routerFakeInfo =
          RouterFakeInfo<T>(routerPath: pageName, arguments: arguments);
      pcRouterFakeProvider.router<T>(routerFakeInfo, clear: clear);

      return routerFakeInfo.completer.future;
    }
  }

  static Future<T?> push<T extends Object?>(
      BuildContext context, MaterialPageRoute<T> route) {
    if (!TableModeUtil.isTableMode()) {
      return Navigator.of(context).push(route);
    } else {
      bool clear = false;
      var parentRouterFake = PcRouterFake.of(context);
      if (parentRouterFake == null) {
        // means this request is from home, globals, search or dms, just to clean stack and push
        clear = true;
      }
      var routerFakeInfo = RouterFakeInfo<T>(buildContent: route.buildContent);
      pcRouterFakeProvider.router<T>(routerFakeInfo, clear: clear);

      return routerFakeInfo.completer.future;
    }
  }

  static Object? routerArgs(BuildContext context) {
    RouteSettings? setting = ModalRoute.of(context)?.settings;
    if (setting != null) {
      if (!TableModeUtil.isTableMode()) {
        return setting.arguments;
      } else {
        var fake = PcRouterFake.of(context);
        if (fake != null) {
          return fake.info.arguments;
        }
      }
    }
    return null;
  }

  static void back(BuildContext context, [Object? returnObj]) {
    NavigatorState ns = Navigator.of(context);

    var parentRouterFake = PcRouterFake.of(context);
    if (parentRouterFake == null) {
      if (ns.canPop()) {
        ns.pop(returnObj);
      }
    } else {
      // handle pop result
      var info = parentRouterFake.info;
      pcRouterFakeProvider.remove(info);
      info.completer.complete(returnObj);
    }
  }
}
