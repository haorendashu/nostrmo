import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:nostrmo/util/string_util.dart';

class LinkPreviewDataProvider extends ChangeNotifier {
  static const CACHE_LENGTH = 100;

  Map<String, PreviewData> _data = {};

  int _index = 0;

  List<String?> _cacheKey = List.filled(CACHE_LENGTH, null);

  void set(String link, PreviewData? data) {
    if (data != null) {
      // remove cache
      var cachedLink = _cacheKey[_index];
      if (StringUtil.isNotBlank(cachedLink)) {
        _data.remove(cachedLink);
      }

      // save new cache
      _data[link] = data;
      _cacheKey[_index] = link;

      // index move to next
      _index++;
      _index %= CACHE_LENGTH;

      notifyListeners();
    }
  }

  PreviewData? getPreviewData(String link) {
    return _data[link];
  }

  void clear() {
    _data.clear();
  }
}
