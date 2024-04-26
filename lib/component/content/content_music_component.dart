import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/music/music_component.dart';
import 'package:nostrmo/component/music/music_info_builder.dart';
import 'package:nostrmo/component/placeholder/music_placeholder.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/music_provider.dart';
import 'package:nostrmo/util/encrypt_util.dart';
import 'package:nostrmo/util/hash_util.dart';

class ContentMusicComponent extends StatefulWidget {
  String? eventId;

  String content;

  MusicInfoBuilder musicInfoBuilder;

  ContentMusicComponent(this.eventId, this.content, this.musicInfoBuilder);

  @override
  State<StatefulWidget> createState() {
    return _ContentMusicComponent();
  }
}

class _ContentMusicComponent extends CustState<ContentMusicComponent> {
  MusicInfo? musicInfo;

  @override
  Widget doBuild(BuildContext context) {
    if (musicInfo == null) {
      return Container(
        margin: const EdgeInsets.only(
          top: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: MusicPlaceholder(),
      );
    }

    return Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      child: MusicComponent(
        musicInfo!,
        key: Key(HashUtil.md5(musicInfo!.sourceUrl!)),
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    musicInfo = musicInfoCache.get(widget.content);
    musicInfo ??=
        await widget.musicInfoBuilder.build(widget.content, widget.eventId);
    if (musicInfo != null) {
      musicInfoCache.put(widget.content, musicInfo!);
    }
    setState(() {});
  }
}
