import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class MusicProvider extends ChangeNotifier {
  Player player = Player();

  MusicInfo? _musicInfo;

  MusicInfo? get musicInfo => _musicInfo;

  Duration? _currentPosition;

  Duration? get currentPosition => _currentPosition;

  Duration? get currentDuration => player.state.duration;

  bool get isPlaying => player.state.playing;

  void init() {
    player.stream.position.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  Future<void> play(MusicInfo mi) async {
    if (isPlaying) {
      await stop();
    }

    _musicInfo = mi;
    player.open(Media(_musicInfo!.audioUrl));

    notifyListeners();
  }

  void playOrPause() {
    player.playOrPause();
    notifyListeners();
  }

  Future<void> stop() async {
    await player.stop();
    _musicInfo = null;
    _currentPosition = null;

    notifyListeners();
  }
}

class MusicInfo {
  final String icon;

  // This music info from with eventId;
  final String? eventId;

  final String title;

  final String name;

  final String audioUrl;

  final String imageUrl;

  final String? sourceUrl;

  MusicInfo(
    this.icon,
    this.eventId,
    this.title,
    this.name,
    this.audioUrl,
    this.imageUrl, {
    this.sourceUrl,
  });
}
