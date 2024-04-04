import 'package:nostrmo/provider/music_provider.dart';

class MusicInfoCache {
  Map<String, MusicInfo> _cache = {};

  MusicInfo? get(String source) {
    return _cache[source];
  }

  void put(String source, MusicInfo musicInfo) {
    _cache[source] = musicInfo;
  }
}
