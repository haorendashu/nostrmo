import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:nostrmo/util/store_util.dart';
import 'package:widget_size/widget_size.dart';

import '../../consts/base64.dart';

class ContentVideoComponent extends StatefulWidget {
  String url;

  ContentVideoComponent({required this.url});

  @override
  State<StatefulWidget> createState() {
    return _ContentVideoComponent();
  }
}

class _ContentVideoComponent extends State<ContentVideoComponent> {
  late final player = Player();
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    bool autoPlay = true;
    if (widget.url.indexOf("http") == 0) {
      player.open(Media(widget.url), play: autoPlay);
    } else if (widget.url.startsWith(BASE64.PREFIX)) {
      StoreUtil.saveBS2TempFileByMd5("mp4", BASE64.toData(widget.url))
          .then((tempFileName) {
        player.open(Media("file:///$tempFileName"), play: autoPlay);
      });
    } else {
      player.open(Media("file:///${widget.url}"), play: autoPlay);
    }
    player.setVolume(0);
  }

  @override
  void dispose() {
    super.dispose();
    controller.player.stop();
    controller.player.dispose();
  }

  double? width;

  @override
  Widget build(BuildContext context) {
    var currentwidth = MediaQuery.of(context).size.width;
    if (width != null) {
      currentwidth = width!;
    }

    Widget videoWidget = Video(
      controller: controller,
      controls: adaptiveVideoControls,
    );
    if (PlatformUtil.isPC()) {
      videoWidget = MaterialDesktopVideoControlsTheme(
        normal: videoDesktopControls(),
        fullscreen: videoDesktopControls(),
        child: videoWidget,
      );
    } else {
      videoWidget = MaterialVideoControlsTheme(
        normal: videoControls(),
        fullscreen: videoControls(),
        child: videoWidget,
      );
    }

    return Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      child: WidgetSize(
        onChange: ((size) {
          setState(() {
            width = size.width;
          });
        }),
        child: Center(
          child: SizedBox(
            width: currentwidth,
            height: currentwidth * 9.0 / 16.0,
            child: videoWidget,
          ),
        ),
      ),
    );
  }

  MaterialDesktopVideoControlsThemeData videoDesktopControls() {
    return const MaterialDesktopVideoControlsThemeData(
      bottomButtonBar: [
        // MaterialDesktopSkipPreviousButton(),
        MaterialDesktopPlayOrPauseButton(),
        // MaterialDesktopSkipNextButton(),
        MaterialDesktopVolumeButton(),
        MaterialDesktopPositionIndicator(),
        Spacer(),
        MaterialDesktopFullscreenButton(),
      ],
    );
  }

  MaterialVideoControlsThemeData videoControls() {
    return const MaterialVideoControlsThemeData(
      volumeGesture: true,
      topButtonBar: [
        Spacer(),
        MaterialDesktopVolumeButton(),
      ],
    );
  }

  Widget adaptiveVideoControls(VideoState state) {
    if (PlatformUtil.isPC()) {
      return MaterialDesktopVideoControls(state);
    } else {
      return MaterialVideoControls(state);
    }
  }
}
