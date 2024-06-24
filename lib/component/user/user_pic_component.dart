import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/setting_provider.dart';
import 'package:nostrmo/util/colors_util.dart';
import 'package:provider/provider.dart';

import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import '../../util/string_util.dart';
import '../image_component.dart';

class UserPicComponent extends StatefulWidget {
  String pubkey;

  double width;

  Metadata? metadata;

  UserPicComponent({
    required this.pubkey,
    required this.width,
    this.metadata,
  });

  @override
  State<StatefulWidget> createState() {
    return _UserPicComponent();
  }
}

class _UserPicComponent extends State<UserPicComponent> {
  @override
  Widget build(BuildContext context) {
    if (widget.metadata != null) {
      return buildWidget(widget.metadata);
    }

    return Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        return buildWidget(metadata);
      },
      selector: (context, _provider) {
        return _provider.getMetadata(widget.pubkey);
      },
    );
  }

  Widget buildWidget(Metadata? metadata) {
    var themeData = Theme.of(context);
    var _settingProvider = Provider.of<SettingProvider>(context);

    if (StringUtil.isNotBlank(widget.pubkey) &&
        _settingProvider.pubkeyColor != OpenStatus.CLOSE) {
      double imageBorder = widget.width / 14;
      Widget? imageWidget;
      if (metadata != null) {
        if (StringUtil.isNotBlank(metadata.picture)) {
          imageWidget = ImageComponent(
            imageUrl: metadata.picture!,
            width: widget.width - imageBorder * 2,
            height: widget.width - imageBorder * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => CircularProgressIndicator(),
          );
        }
      }

      return Container(
        width: widget.width,
        height: widget.width,
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.width / 2),
          color: ColorsUtil.hexToColor("#${widget.pubkey.substring(0, 6)}"),
        ),
        child: Container(
          width: widget.width - imageBorder * 2,
          height: widget.width - imageBorder * 2,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.width / 2 - imageBorder),
            color: themeData.hintColor,
          ),
          child: imageWidget,
        ),
      );
    }

    Widget? imageWidget;
    if (metadata != null) {
      if (StringUtil.isNotBlank(metadata.picture)) {
        imageWidget = ImageComponent(
          imageUrl: metadata.picture!,
          width: widget.width,
          height: widget.width,
          fit: BoxFit.cover,
          placeholder: (context, url) => CircularProgressIndicator(),
        );
      }
    }

    return Container(
      width: widget.width,
      height: widget.width,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.width / 2),
        color: themeData.hintColor,
      ),
      child: imageWidget,
    );
  }
}
