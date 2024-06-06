import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class LinkPreviewDataProvider extends ChangeNotifier {
  Map<String, PreviewData> _datas = {};

  void set(String link, PreviewData? data) {
    var oldData = _datas[link];
    if (data != null && (oldData == null || oldData != data)) {
      _datas[link] = data;
      notifyListeners();
    }
  }

  PreviewData? getPreviewData(String link) {
    return _datas[link];
  }

  void clear() {
    _datas.clear();
  }
}
