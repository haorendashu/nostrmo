import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../client/nip19/nip19.dart';
import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../util/string_util.dart';
import 'metadata_component.dart';

class MetadataTopComponent extends StatefulWidget {
  String pubKey;

  Metadata? metadata;

  MetadataTopComponent({required this.pubKey, this.metadata});

  @override
  State<StatefulWidget> createState() {
    return _MetadataTopComponent();
  }
}

class _MetadataTopComponent extends State<MetadataTopComponent> {
  static const double IMAGE_BORDER = 4;

  static const double IMAGE_WIDTH = 80;

  static const double HALF_IMAGE_WIDTH = 40;

  late String nip19PubKey;

  @override
  void initState() {
    super.initState();

    nip19PubKey = Nip19.encodePubKey(widget.pubKey);
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    var maxWidth = MediaQuery.of(context).size.width;
    var bannerHeight = maxWidth / 3;

    String nip19Name = Nip19.encodeSimplePubKey(widget.pubKey);
    String displayName = nip19Name;
    String? name;
    if (widget.metadata != null) {
      if (StringUtil.isNotBlank(widget.metadata!.displayName)) {
        displayName = widget.metadata!.displayName!;
      }
      if (StringUtil.isNotBlank(widget.metadata!.name)) {
        name = widget.metadata!.name;
      }
    }

    Widget? imageWidget;
    if (widget.metadata != null &&
        StringUtil.isNotBlank(widget.metadata!.picture)) {
      imageWidget = CachedNetworkImage(
        imageUrl: widget.metadata!.picture!,
        width: IMAGE_WIDTH,
        height: IMAGE_WIDTH,
        fit: BoxFit.cover,
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
      );
    }
    Widget? bannerImage;
    if (widget.metadata != null &&
        StringUtil.isNotBlank(widget.metadata!.banner)) {
      bannerImage = CachedNetworkImage(
        imageUrl: widget.metadata!.banner!,
        width: maxWidth,
        height: bannerHeight,
        fit: BoxFit.cover,
      );
    }

    List<Widget> topList = [];
    topList.add(Container(
      width: maxWidth,
      height: bannerHeight,
      color: Colors.grey.withOpacity(0.5),
      child: bannerImage,
    ));
    topList.add(Container(
      height: 50,
      // color: Colors.red,
      child: Row(
        children: [
          Expanded(
            child: Container(),
          ),
          wrapBtn(MetadataIconBtn(
            iconData: Icons.currency_bitcoin,
            onTap: () {},
          )),
          wrapBtn(MetadataIconBtn(
            iconData: Icons.mail,
            onTap: () {},
          )),
          wrapBtn(MetadataTextBtn(
            text: "Follow",
            onTap: () {},
          )),
        ],
      ),
    ));
    topList.add(Container(
      // height: 40,
      width: double.maxFinite,
      margin: EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        // top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      // color: Colors.green,
      child: Row(
        children: [
          Text(
            displayName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: Base.BASE_PADDING_HALF),
            child: Text(
              name != null ? "@" + name : "",
              style: TextStyle(
                fontSize: 15,
                color: hintColor,
              ),
            ),
          )
        ],
      ),
    ));
    if (widget.metadata != null) {
      topList.add(MetadataIconDataComp(
        iconData: Icons.key,
        text: nip19PubKey,
        textBG: true,
        onTap: copyPubKey,
      ));
      if (StringUtil.isNotBlank(widget.metadata!.nip05)) {
        topList.add(MetadataIconDataComp(
          iconData: Icons.check_circle,
          text: widget.metadata!.nip05!,
          iconColor: mainColor,
        ));
      }
      if (widget.metadata != null) {
        if (StringUtil.isNotBlank(widget.metadata!.website)) {
          topList.add(MetadataIconDataComp(
            iconData: Icons.link,
            text: widget.metadata!.website!,
          ));
        }
        if (StringUtil.isNotBlank(widget.metadata!.lud16)) {
          topList.add(MetadataIconDataComp(
            iconData: Icons.bolt,
            iconColor: Colors.orange,
            text: widget.metadata!.lud16!,
          ));
        }
      }
    }

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: topList,
        ),
        Positioned(
          left: Base.BASE_PADDING,
          top: bannerHeight - HALF_IMAGE_WIDTH,
          child: Container(
            height: IMAGE_WIDTH + IMAGE_BORDER * 2,
            width: IMAGE_WIDTH + IMAGE_BORDER * 2,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(HALF_IMAGE_WIDTH + IMAGE_BORDER),
              border: Border.all(
                width: IMAGE_BORDER,
                color: scaffoldBackgroundColor,
              ),
            ),
            child: Container(
              alignment: Alignment.center,
              height: IMAGE_WIDTH,
              width: IMAGE_WIDTH,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(HALF_IMAGE_WIDTH),
                color: Colors.grey,
              ),
              child: imageWidget,
            ),
          ),
        )
      ],
    );
  }

  Widget wrapBtn(Widget child) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: child,
    );
  }

  copyPubKey() {
    print("try to copy");
    Clipboard.setData(ClipboardData(text: nip19PubKey)).then((_) {
      BotToast.showText(text: "key has been copy!");
    });
  }
}

class MetadataIconBtn extends StatelessWidget {
  void Function() onTap;

  IconData iconData;

  MetadataIconBtn({required this.iconData, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 28,
          width: 28,
          child: Icon(
            iconData,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class MetadataTextBtn extends StatelessWidget {
  void Function() onTap;

  String text;

  MetadataTextBtn({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 28,
          padding: EdgeInsets.only(left: 8, right: 8),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class MetadataIconDataComp extends StatelessWidget {
  String text;

  IconData iconData;

  Color? iconColor;

  bool textBG;

  Function? onTap;

  MetadataIconDataComp({
    required this.text,
    required this.iconData,
    this.iconColor,
    this.textBG = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: Base.BASE_PADDING_HALF,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (onTap != null) {
            onTap!();
          }
        },
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.only(
                right: Base.BASE_PADDING_HALF,
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 16,
              ),
            ),
            Expanded(
              child: Container(
                padding: textBG
                    ? EdgeInsets.only(
                        left: Base.BASE_PADDING_HALF,
                        right: Base.BASE_PADDING_HALF,
                        top: 4,
                        bottom: 4,
                      )
                    : null,
                decoration: BoxDecoration(
                  color: textBG ? Colors.grey[300] : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
