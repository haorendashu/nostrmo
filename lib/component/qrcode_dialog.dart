import 'dart:typed_data';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/component/name_component.dart';
import 'package:nostrmo/component/user/metadata_top_component.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../consts/base.dart';
import '../provider/metadata_provider.dart';
import '../util/router_util.dart';
import '../util/store_util.dart';
import '../util/string_util.dart';

class QrcodeDialog extends StatefulWidget {
  String pubkey;

  QrcodeDialog({required this.pubkey});

  static Future<String?> show(BuildContext context, String pubkey) async {
    return await showDialog<String>(
        context: context,
        builder: (_context) {
          return QrcodeDialog(
            pubkey: pubkey,
          );
        });
  }

  @override
  State<StatefulWidget> createState() {
    return _QrcodeDialog();
  }
}

class _QrcodeDialog extends State<QrcodeDialog> {
  static const double IMAGE_WIDTH = 40;
  static const double QR_WIDTH = 200;

  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    List<Widget> list = [];
    var nip19Pubkey = Nip19.encodePubKey(widget.pubkey);
    Widget topWidget = Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        Widget? imageWidget;
        if (metadata != null && StringUtil.isNotBlank(metadata.picture)) {
          imageWidget = CachedNetworkImage(
            imageUrl: metadata.picture!,
            width: IMAGE_WIDTH,
            height: IMAGE_WIDTH,
            fit: BoxFit.cover,
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => Icon(Icons.error),
          );
        }

        Widget userImageWidget = Container(
          alignment: Alignment.center,
          height: IMAGE_WIDTH,
          width: IMAGE_WIDTH,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
            color: Colors.grey,
          ),
          child: imageWidget,
        );

        Widget userNameWidget = NameComponnet(
          pubkey: widget.pubkey,
          metadata: metadata,
        );

        return Container(
          width: QR_WIDTH,
          margin: const EdgeInsets.only(
            left: Base.BASE_PADDING_HALF,
            right: Base.BASE_PADDING_HALF,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              userImageWidget,
              Container(
                margin: EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                child: Container(
                  width: QR_WIDTH - IMAGE_WIDTH - Base.BASE_PADDING_HALF,
                  child: userNameWidget,
                ),
              ),
            ],
          ),
        );
      },
      selector: (content, _provider) {
        return _provider.getMetadata(widget.pubkey);
      },
    );
    list.add(topWidget);
    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
        left: Base.BASE_PADDING_HALF,
        right: Base.BASE_PADDING_HALF,
      ),
      child: PrettyQr(
        data: nip19Pubkey,
        size: QR_WIDTH,
        image: AssetImage("assets/imgs/logo/logo512.png"),
      ),
    ));
    list.add(GestureDetector(
      onTap: () {
        _doCopy(nip19Pubkey);
      },
      child: Container(
        width: QR_WIDTH + Base.BASE_PADDING_HALF * 2,
        padding: EdgeInsets.all(Base.BASE_PADDING_HALF),
        decoration: BoxDecoration(
          color: hintColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SelectableText(
          nip19Pubkey,
          onTap: () {
            _doCopy(nip19Pubkey);
          },
        ),
      ),
    ));

    var main = Stack(
      children: [
        Screenshot(
          controller: screenshotController,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: list,
            ),
          ),
        ),
        Positioned(
          right: Base.BASE_PADDING_HALF,
          top: Base.BASE_PADDING_HALF,
          child: MetadataIconBtn(
            iconData: Icons.share,
            onTap: onShareTap,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }

  void _doCopy(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      BotToast.showText(text: "Pubkey copy success!");
    });
  }

  void onShareTap() {
    screenshotController.capture().then((Uint8List? imageData) async {
      if (imageData != null) {
        if (imageData != null) {
          var tempFile = await StoreUtil.saveBS2TempFile(
            "png",
            imageData,
          );
          Share.shareXFiles([XFile(tempFile)]);
        }
      }
    }).catchError((onError) {
      print(onError);
    });
  }
}
