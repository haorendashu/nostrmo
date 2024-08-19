import 'package:flutter/material.dart';
import 'package:nostrmo/component/user/simple_name_component.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import '../image_component.dart';
import '../user/user_pic_component.dart';

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
            child: SimpleNameComponent(
              pubkey: widget.pubkey,
              metadata: metadata,
              maxLines: 1,
              textOverflow: TextOverflow.ellipsis,
            ),
          );

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
            child: UserPicComponent(
              pubkey: widget.pubkey,
              width: IMAGE_WIDTH,
              metadata: metadata,
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
