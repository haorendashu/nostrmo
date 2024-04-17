import 'package:flutter/material.dart';
import 'package:nostrmo/component/name_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:provider/provider.dart';

import '../../util/string_util.dart';
import '../image_component.dart';

class SimpleMetadataComponent extends StatefulWidget {
  String pubkey;

  Metadata? metadata;

  SimpleMetadataComponent({
    required this.pubkey,
    this.metadata,
  });

  @override
  State<StatefulWidget> createState() {
    return _SimpleMetadataComponent();
  }
}

class _SimpleMetadataComponent extends State<SimpleMetadataComponent> {
  static const double IMAGE_WIDTH = 50;

  static const double HALF_IMAGE_WIDTH = 25;

  static const double HEIGHT = 64;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    if (widget.metadata != null) {
      return buildWidget(themeData, widget.metadata!);
    }

    return Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
      if (metadata == null) {
        return Container(
          height: HEIGHT,
          color: themeData.hintColor,
        );
      }

      return buildWidget(themeData, metadata);
    }, selector: (context, provider) {
      return provider.getMetadata(widget.pubkey);
    });
  }

  Widget buildWidget(ThemeData themeData, Metadata metadata) {
    var cardColor = themeData.cardColor;

    Widget? imageWidget;
    if (StringUtil.isNotBlank(metadata.picture)) {
      imageWidget = ImageComponent(
        imageUrl: metadata.picture!,
        width: IMAGE_WIDTH,
        height: IMAGE_WIDTH,
        fit: BoxFit.cover,
        placeholder: (context, url) => CircularProgressIndicator(),
      );
    }
    Widget? bannerImage;
    if (StringUtil.isNotBlank(metadata.banner)) {
      bannerImage = ImageComponent(
        imageUrl: metadata.banner!,
        width: double.maxFinite,
        height: HEIGHT,
        fit: BoxFit.fitWidth,
      );
    }

    Widget userImageWidget = Container(
      alignment: Alignment.center,
      height: IMAGE_WIDTH,
      width: IMAGE_WIDTH,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HALF_IMAGE_WIDTH),
        color: Colors.grey,
      ),
      margin: const EdgeInsets.only(
        right: Base.BASE_PADDING,
      ),
      child: imageWidget,
    );

    return Container(
      height: HEIGHT,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ImageComponent(
            imageUrl: metadata.banner!,
            width: double.maxFinite,
            height: HEIGHT,
            fit: BoxFit.fitWidth,
            placeholder: (context, url) => CircularProgressIndicator(),
          ),
          Container(
            height: HEIGHT,
            color: cardColor.withOpacity(0.4),
          ),
          Container(
            padding: const EdgeInsets.only(left: Base.BASE_PADDING),
            child: Row(
              children: [
                userImageWidget,
                NameComponnet(
                  pubkey: metadata.pubKey!,
                  metadata: metadata,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
