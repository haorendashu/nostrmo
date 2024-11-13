import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/src/in_app_webview/in_app_webview_controller.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/main.dart';

class WebViewProvider extends ChangeNotifier with WidgetsBindingObserver {
  WebViewProvider._() {}

  static WebViewProvider? _instance;

  static WebViewProvider getInstance() {
    if (_instance == null) {
      _instance = WebViewProvider._();
      WidgetsBinding.instance.addObserver(_instance!);
    }

    return _instance!;
  }

  String? _url;

  bool _showable = true;

  String? get url => _url;

  bool get showable => _showable;

  Completer? openCompleter;

  InAppWebViewController? webviewController;

  void open(String url) {
    this._url = url;
    this._showable = true;
    notifyListeners();
  }

  void close() {
    this._url = null;
    this._showable = false;
    this.webviewController = null;
    notifyListeners();
  }

  @override
  Future<bool> didPopRoute() async {
    if (_showable && StringUtil.isNotBlank(_url)) {
      if (webviewController != null && await webviewController!.canGoBack()) {
        webviewController!.goBack();
      } else {
        close();
      }
      return true;
    }
    return false;
  }

  void hide() {
    _showable = false;
    notifyListeners();
  }

  void show() {
    _showable = true;
    notifyListeners();
  }

  Future openWithFuture(String url) {
    if (openCompleter != null) {
      openCompleter!.complete();
    }

    this._url = url;
    this._showable = true;
    openCompleter = Completer();

    notifyListeners();
    return openCompleter!.future;
  }

  void closeAndReturn(dynamic result) {
    close();

    if (openCompleter != null) {
      openCompleter!.complete(result);
    }
  }

  WebviewNavigatorObserver webviewNavigatorObserver =
      WebviewNavigatorObserver();
}

class WebviewNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? currentRoute;

  bool canPop() {
    if (currentRoute != null && currentRoute!.navigator != null) {
      return currentRoute!.navigator!.canPop();
    }

    return false;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRoute = route;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    currentRoute = newRoute;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRoute = route;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRoute = route;
  }
}
