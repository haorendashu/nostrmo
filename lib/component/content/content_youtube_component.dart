import 'package:flutter/material.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'content_link_pre_component.dart';

class ContnetYoutubeComponent extends StatelessWidget {
  String link;

  ContnetYoutubeComponent({
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    var videoId = YoutubePlayer.convertUrlToId(link);
    if (StringUtil.isBlank(videoId)) {
      return ContentLinkPreComponent(
        link: link,
      );
    }

    return YoutubePlayer(
      controller: YoutubePlayerController(
          initialVideoId: videoId!,
          flags: YoutubePlayerFlags(
            autoPlay: false,
          )),
    );
  }
}
