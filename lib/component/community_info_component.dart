import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/component/content/content_decoder.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/string_util.dart';

import '../client/nip172/community_info.dart';
import '../main.dart';

class CommunityInfoComponent extends StatefulWidget {
  CommunityInfo info;

  CommunityInfoComponent({required this.info});

  @override
  State<StatefulWidget> createState() {
    return _CommunityInfoComponent();
  }
}

class _CommunityInfoComponent extends State<CommunityInfoComponent> {
  static const double IMAGE_WIDTH = 40;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    Widget? imageWidget;
    if (StringUtil.isNotBlank(widget.info.image)) {
      imageWidget = CachedNetworkImage(
        imageUrl: widget.info!.image!,
        width: IMAGE_WIDTH,
        height: IMAGE_WIDTH,
        fit: BoxFit.cover,
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
        cacheManager: localCacheManager,
      );
    }

    List<Widget> list = [
      Container(
        margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.center,
              height: IMAGE_WIDTH,
              width: IMAGE_WIDTH,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
                color: Colors.grey,
              ),
              child: imageWidget,
            ),
            Container(
              margin: EdgeInsets.only(
                left: Base.BASE_PADDING,
              ),
              child: Text(widget.info.communityId.title),
            ),
            // Expanded(child: Container()),
            Container(
              margin: EdgeInsets.only(
                left: Base.BASE_PADDING_HALF,
                right: Base.BASE_PADDING_HALF,
              ),
              child: Icon(Icons.star_border),
            ),
          ],
        ),
      ),
    ];

    list.addAll(ContentDecoder.decode(context, widget.info.description, null));

    return Container(
      decoration: BoxDecoration(color: cardColor),
      padding: EdgeInsets.all(Base.BASE_PADDING),
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: Column(
        children: list,
      ),
    );
  }
}
