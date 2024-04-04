import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nostrmo/component/webview_router.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/duartion_tool.dart';
import 'package:provider/provider.dart';

import '../../provider/music_provider.dart';
import '../image_component.dart';

class MusicComponent extends StatefulWidget {
  MusicInfo musicInfo;

  bool clearAble;

  MusicComponent(this.musicInfo, {super.key, this.clearAble = false});

  @override
  State<StatefulWidget> createState() {
    return _MusicComponent();
  }
}

class _MusicComponent extends State<MusicComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var titleFontSize = themeData.textTheme.bodyMedium!.fontSize;
    var nameFontSize = themeData.textTheme.bodySmall!.fontSize;
    var hintColor = themeData.hintColor;

    var subInfoTextStyle = TextStyle(
      fontSize: nameFontSize,
      fontWeight: FontWeight.w500,
      color: hintColor,
    );

    var _musicProvider = Provider.of<MusicProvider>(context);
    var currentDuration = _musicProvider.currentDuration;
    var currentPosition = _musicProvider.currentPosition;
    bool isCurrent = false;
    if (_musicProvider.musicInfo != null &&
        _musicProvider.musicInfo!.sourceUrl == widget.musicInfo.sourceUrl) {
      isCurrent = true;
    }

    var imageHeight = (titleFontSize! + nameFontSize!) * 1.7;

    var imageWidget = ImageComponent(
      imageUrl: widget.musicInfo.imageUrl,
    );

    var btnIcon = Icons.play_circle_outline;
    if (isCurrent && _musicProvider.isPlaying) {
      btnIcon = Icons.pause_circle_outline;
    }

    List<Widget> musicSubInfos = [
      Container(
        margin: const EdgeInsets.only(right: Base.BASE_PADDING_HALF),
        child: Image.asset(
          widget.musicInfo.icon,
          width: 18,
          height: 18,
        ),
      ),
      Text(
        widget.musicInfo.name,
        style: subInfoTextStyle,
      ),
    ];
    if (isCurrent &&
        currentDuration != null &&
        currentPosition != null &&
        currentPosition.inSeconds > 0 &&
        currentDuration.inSeconds > 0) {
      musicSubInfos.add(Text(
        "  •  ${currentPosition.prettyDuration()} / ${currentDuration.prettyDuration()}",
        style: subInfoTextStyle,
      ));
    }

    List<Widget> topList = [
      Container(
        width: imageHeight,
        height: imageHeight,
        child: imageWidget,
      ),
      Expanded(
          child: Container(
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.musicInfo.title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: musicSubInfos,
            ),
          ],
        ),
      )),
      Container(
        width: imageHeight,
        height: imageHeight,
        child: GestureDetector(
          onTap: () {
            if (isCurrent) {
              musicProvider.playOrPause();
            } else {
              musicProvider.play(widget.musicInfo);
            }
          },
          child: Icon(btnIcon),
        ),
      ),
    ];
    if (widget.clearAble) {
      topList.add(Container(
        width: imageHeight,
        height: imageHeight,
        child: GestureDetector(
          onTap: () {
            musicProvider.stop();
          },
          child: Icon(Icons.clear),
        ),
      ));
    }

    var topWidget = Row(
      children: topList,
    );

    Widget progressBar = Container();
    if (_musicProvider.isPlaying && isCurrent) {
      double? value;
      if (currentDuration != null &&
          currentPosition != null &&
          currentPosition.inSeconds > 0 &&
          currentDuration.inSeconds > 0) {
        value = currentPosition.inSeconds / currentDuration.inSeconds;
      }
      progressBar = LinearProgressIndicator(
        value: value,
      );
    }

    return GestureDetector(
      onTap: () {
        if (widget.musicInfo.sourceUrl != null &&
            widget.musicInfo.sourceUrl!.indexOf("http") == 0) {
          WebViewRouter.open(context, widget.musicInfo.sourceUrl!);
        }
      },
      child: Container(
        color: cardColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: imageHeight,
              child: topWidget,
            ),
            progressBar,
          ],
        ),
      ),
    );
  }
}
