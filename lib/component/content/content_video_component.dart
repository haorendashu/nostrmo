import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/store_util.dart';
import 'package:widget_size/widget_size.dart';

import '../../consts/base64.dart';

class ContentVideoComponent extends StatefulWidget {
  String url;

  bool autoPlay;

  ContentVideoComponent({required this.url, this.autoPlay = true});

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
    bool autoPlay = widget.autoPlay;
    player.stream.height.listen((v) {
      if (v != null && videoHeight == null) {
        setState(() {
          videoHeight = v;
        });
      }
    });
    player.stream.width.listen((v) {
      if (v != null && videoWidth == null) {
        setState(() {
          videoWidth = v;
        });
      }
    });
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

  int? videoWidth;

  int? videoHeight;

  @override
  void dispose() {
    super.dispose();
    controller.player.stop();
    controller.player.dispose();
  }

  double? width;

  @override
  Widget build(BuildContext context) {
    var currentWidth = MediaQuery.of(context).size.width;
    if (width != null) {
      currentWidth = width!;
    }
    var currentHeight = currentWidth * 9.0 / 16.0;

    videoWidth = player.state.width;
    videoHeight = player.state.height;

    if (videoWidth != null && videoHeight != null) {
      if (videoHeight! / videoWidth! > 1.2) {
        currentWidth = currentWidth * 0.6;
      }
      currentHeight =
          currentWidth / videoWidth!.toDouble() * videoHeight!.toDouble();
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
        fullscreen: videoFullControls(),
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
            width: currentWidth,
            height: currentHeight,
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
      topButtonBar: [
        Spacer(),
        MaterialDesktopVolumeButton(),
      ],
    );
  }

  MaterialVideoControlsThemeData videoFullControls() {
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
