import 'package:nostrmo/component/music/music_component.dart';
import 'package:nostrmo/component/music/music_info_builder.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/music_provider.dart';
import 'package:nostrmo/util/string_util.dart';

import '../content/content_decoder.dart';

BlankLinkMusicInfoBuilder blankLinkMusicInfoBuilder =
    BlankLinkMusicInfoBuilder();

class BlankLinkMusicInfoBuilder extends MusicInfoBuilder {
  @override
  Future<MusicInfo?> build(String content, String? eventId) async {
    String? imageUrl = "";
    String? name;
    if (StringUtil.isNotBlank(eventId)) {
      var event = singleEventProvider.getEvent(eventId!);
      if (event != null) {
        var metadata = metadataProvider.getMetadata(event.pubKey);
        if (metadata != null) {
          imageUrl = metadata.picture;
          name = metadata.name;
        }
      }
    }

    return MusicInfo("", eventId, content, name, content, imageUrl,
        sourceUrl: content);
  }

  @override
  bool check(String content) {
    return ContentDecoder.getPathType(content) == "audio";
  }
}
