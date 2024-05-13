import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../client/nip19/nip19.dart';
import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import '../../util/string_util.dart';
import '../image_component.dart';

class ZapBottomSheetUserComponent extends StatefulWidget {
  String pubkey;

  bool configMaxWidth;

  ZapBottomSheetUserComponent(
    this.pubkey, {
    this.configMaxWidth = false,
  });

  @override
  State<StatefulWidget> createState() {
    return _ZapBottomSheetUserComponent();
  }
}

class _ZapBottomSheetUserComponent extends State<ZapBottomSheetUserComponent> {
  static const double IMAGE_BORDER = 3;

  static const double IMAGE_WIDTH = 60;

  static const double HALF_IMAGE_WIDTH = 30;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;

    return Container(
      child: Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
          String nip19Name = Nip19.encodeSimplePubKey(widget.pubkey);
          String displayName = "";
          String? name;
          if (metadata != null) {
            if (StringUtil.isNotBlank(metadata.displayName)) {
              displayName = metadata.displayName!;
              if (StringUtil.isNotBlank(metadata.name)) {
                name = metadata.name;
              }
            } else if (StringUtil.isNotBlank(metadata.name)) {
              displayName = metadata.name!;
            }
          }
          if (StringUtil.isBlank(displayName)) {
            displayName = nip19Name;
          }
          List<TextSpan> nameSpans = [];
          nameSpans.add(TextSpan(
            text: displayName,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ));
          if (StringUtil.isNotBlank(name)) {
            nameSpans.add(TextSpan(
              text: name != null ? "@$name" : "",
              style: TextStyle(
                fontSize: fontSize,
                color: hintColor,
              ),
            ));
          }

          Widget userNameComponent = Container(
            width: widget.configMaxWidth ? 100 : null,
            // height: 40,
            margin: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
              // top: Base.BASE_PADDING_HALF,
              bottom: Base.BASE_PADDING_HALF,
            ),
            // color: Colors.green,
            alignment: Alignment.center,
            child: Text.rich(
              TextSpan(
                children: nameSpans,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );

          Widget? imageWidget;
          if (metadata != null && StringUtil.isNotBlank(metadata.picture)) {
            print(metadata.picture);
            imageWidget = ImageComponent(
              imageUrl: metadata.picture!,
              width: IMAGE_WIDTH,
              height: IMAGE_WIDTH,
              fit: BoxFit.cover,
              placeholder: (context, url) => CircularProgressIndicator(),
            );
          }
          Widget userImageWidget = Container(
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
          );

          return Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                userImageWidget,
                Container(
                  child: userNameComponent,
                ),
              ],
            ),
          );
        },
        selector: (context, _provider) {
          return _provider.getMetadata(widget.pubkey);
        },
      ),
    );
  }
}
