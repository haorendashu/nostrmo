import 'package:nostrmo/provider/music_provider.dart';

abstract class MusicInfoBuilder {
  bool check(String content);

  Future<MusicInfo?> build(String content, String? eventId);
}
