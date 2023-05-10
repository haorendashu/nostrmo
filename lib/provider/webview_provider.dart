import 'package:flutter/material.dart';

class WebViewProvider extends ChangeNotifier {
  String? _url;

  bool _showable = true;

  String? get url => _url;

  bool get showable => _showable;

  void open(String url) {
    this._url = url;
    this._showable = true;
    notifyListeners();
  }

  void close() {
    this._url = null;
    this._showable = false;
    notifyListeners();
  }

  void hide() {
    _showable = false;
    notifyListeners();
  }

  void show() {
    _showable = true;
    notifyListeners();
  }
}
