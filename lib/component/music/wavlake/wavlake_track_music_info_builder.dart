import 'dart:convert';
import 'dart:developer';

import 'package:nostrmo/component/music/music_info_builder.dart';
import 'package:nostrmo/provider/music_provider.dart';
import 'package:nostrmo/util/dio_util.dart';
import 'package:nostrmo/util/spider_util.dart';
import 'package:nostrmo/util/string_util.dart';

WavlakeTrackMusicInfoBuilder wavlakeTrackMusicInfoBuilder =
    WavlakeTrackMusicInfoBuilder();

class WavlakeTrackMusicInfoBuilder extends MusicInfoBuilder {
  static const String prefix0 = "https://wavlake.com/track/";
  static const String prefix1 = "https://wavlake.com/episode/";

  @override
  Future<MusicInfo?> build(String content, String? eventId) async {
    // try to fetch info from api
    try {
      var id = content.replaceAll(prefix0, "");
      id = id.replaceAll(prefix1, "");
      var jsonObj = await DioUtil.get(
          "https://catalog-prod-dot-wavlake-alpha.uc.r.appspot.com/v1/episodes/${id}");
      if (jsonObj != null && jsonObj["success"] == true) {
        var name = jsonObj["data"]["podcast"]["name"];
        var title = jsonObj["data"]["title"];

        var imageUrl = jsonObj["data"]["podcast"]["artworkUrl"];
        var audioUrl = jsonObj["data"]["liveUrl"];

        return MusicInfo(
            "assets/imgs/music/wavlake.png",
            eventId,
            title,
            name,
            audioUrl,
            "https://wavlake.com/_next/image?url=${Uri.encodeQueryComponent(imageUrl)}&w=256&q=75",
            sourceUrl: content);
      }
    } catch (e) {}

    String? source = await DioUtil.getStr(content);
    if (StringUtil.isBlank(source)) {
      return null;
    }

    String nameAndTitleStr =
        SpiderUtil.subUntil(source!, "<title>", "</title>");
    var strs = nameAndTitleStr.split("•");
    if (strs.length < 2) {
      return null;
    }
    var name = strs[0].trim();
    var title = strs[1].trim();

    String imageUrl =
        SpiderUtil.subUntil(source, '<meta property="og:image" content="', '"');
    String audioUrl =
        SpiderUtil.subUntil(source, '<meta property="og:audio" content="', '"');

    if (StringUtil.isBlank(audioUrl) || audioUrl.indexOf("http") != 0) {
      return null;
    }

    return MusicInfo(
        "assets/imgs/music/wavlake.png",
        eventId,
        title,
        name,
        audioUrl,
        "https://wavlake.com/_next/image?url=${Uri.encodeQueryComponent(imageUrl)}&w=256&q=75",
        sourceUrl: content);
  }

  @override
  bool check(String content) {
    if (content.indexOf(prefix0) == 0) {
      return true;
    }
    if (content.indexOf(prefix1) == 0) {
      return true;
    }

    return false;
  }
}
