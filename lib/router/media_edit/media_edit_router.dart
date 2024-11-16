import 'dart:io';
import 'dart:typed_data';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/utils/path_type_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/content/content_image_component.dart';
import 'package:nostrmo/component/content/content_video_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/provider/uploader.dart';
import 'package:image/image.dart' as img;

import '../../component/appbar_back_btn_component.dart';
import '../../component/image_component.dart';
import '../../consts/base64.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/hash_util.dart';
import '../../util/router_util.dart';
import '../../util/store_util.dart';
import '../../util/theme_util.dart';

class MediaEditRouter extends StatefulWidget {
  String filePath;

  MediaEditRouter({required this.filePath});

  static Future<Event?> pickAndUpload(BuildContext context) async {
    var filePath = await Uploader.pick(context);
    if (StringUtil.isBlank(filePath)) {
      return null;
    }

    var editor = MediaEditRouter(
      filePath: filePath!,
    );

    return RouterUtil.push(context, MaterialPageRoute(builder: (context) {
      return editor;
    }));
  }

  @override
  State<StatefulWidget> createState() {
    return _MediaEditRouter();
  }
}

class _MediaEditRouter extends State<MediaEditRouter> {
  int eventKind = EventKind.FILE_HEADER;

  TextEditingController textEditingController = TextEditingController();

  String? mimeType;

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var textColor = themeData.textTheme.bodyMedium!.color;
    var cardColor = themeData.cardColor;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;

    mimeType = lookupMimeType(widget.filePath);
    if (StringUtil.isNotBlank(mimeType)) {
      var pathType = PathTypeUtil.getPathType(widget.filePath);
      if (pathType == "image") {
        mimeType = "image/jpeg";
      } else if (pathType == "video") {
        mimeType = "video/mp4";
      }
    }

    if (StringUtil.isBlank(mimeType)) {
      RouterUtil.back(context);
      return Container();
    }

    bool isVideo = false;
    if (mimeType!.contains("video")) {
      isVideo = true;
    } else if (mimeType!.contains("image")) {
      isVideo = false;
    } else {
      RouterUtil.back(context);
      return Container();
    }

    List<Widget> list = [];
    if (isVideo) {
      list.add(ContentVideoComponent(
        url: widget.filePath,
        autoPlay: false,
      ));
    } else {
      var imageUrl = widget.filePath;
      late Widget imageWidget;
      if (imageUrl.indexOf("http") == 0 ||
          imageUrl.indexOf(BASE64.PREFIX) == 0) {
        // netword image
        imageWidget = ImageComponent(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => CircularProgressIndicator(),
        );
      } else {
        // local image
        imageWidget = Image.file(
          File(imageUrl),
          fit: BoxFit.cover,
        );
      }

      list.add(imageWidget);
    }

    list.add(
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          // color: ThemeUtil.getDialogCoverColor(themeData),
          color: Colors.white.withOpacity(0.2),
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
            top: Base.BASE_PADDING_HALF,
            bottom: Base.BASE_PADDING_HALF,
          ),
          child: TextField(
            controller: textEditingController,
            minLines: 1,
            maxLines: 10,
            autofocus: true,
            decoration: InputDecoration(
              hintText: s.What_s_happening,
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        // title: Text("Note"),
        backgroundColor: cardColor,
        leading: AppbarBackBtnComponent(),
        actions: [
          Container(
            child: TextButton(
              child: Text(
                s.Send,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                ),
              ),
              onPressed: doSave,
              style: ButtonStyle(),
            ),
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: cardColor,
        child: Stack(
          alignment: Alignment.center,
          children: list,
        ),
      ),
    );
  }

  Future<void> doSave() async {
    if (StringUtil.isBlank(mimeType)) {
      return;
    }

    Event? event;
    var cancelFunc = BotToast.showLoading();
    try {
      var file = File(widget.filePath);
      var bytes = await file.readAsBytes();
      var size = bytes.length;
      var ox = HashUtil.sha256Bytes(bytes);

      List tags = [];

      tags.add(["m", mimeType]);
      tags.add(["ox", ox]);
      tags.add(["size", size]);

      if (mimeType!.contains("image")) {
        final image = img.decodeImage(bytes);
        final blurHash = BlurHash.encode(image!, numCompX: 4, numCompY: 3);

        tags.add(["blurhash", blurHash.hash]);
        tags.add(["dim", "${image.width}x${image.height}"]);
      }

      // This oper can clear the mem ??
      bytes = Uint8List(0);

      var url = await Uploader.upload(
        widget.filePath,
        imageService: settingProvider.imageService,
      );

      tags.add(["url", url]);

      var content = textEditingController.text;
      event = Event(nostr!.publicKey, EventKind.FILE_HEADER, tags, content);
      event = await nostr!.sendEvent(event);
    } finally {
      cancelFunc.call();
    }

    RouterUtil.back(context, event);
  }
}
