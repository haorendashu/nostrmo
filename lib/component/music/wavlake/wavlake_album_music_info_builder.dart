import 'dart:developer';

import 'package:nostrmo/component/music/music_info_builder.dart';
import 'package:nostrmo/provider/music_provider.dart';

import '../../../util/dio_util.dart';
import '../../../util/spider_util.dart';
import '../../../util/string_util.dart';

WavlakeAlbumMusicInfoBuilder wavlakeAlbumMusicInfoBuilder =
    WavlakeAlbumMusicInfoBuilder();

class WavlakeAlbumMusicInfoBuilder extends MusicInfoBuilder {
  static const String prefix0 = "https://wavlake.com/album/";

  @override
  Future<MusicInfo?> build(String content, String? eventId) async {
    String? source = await DioUtil.getStr(content);
    if (StringUtil.isBlank(source)) {
      return null;
    }

    log(source!);

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
    String audioUrl = SpiderUtil.subUntil(source, '"liveUrl":"', '"');

    print(audioUrl);

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

    return false;
  }
}
