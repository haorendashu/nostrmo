import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip172/community_info.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'content/content_component.dart';
import 'image_component.dart';

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
      imageWidget = ImageComponent(
        imageUrl: widget.info!.image!,
        width: IMAGE_WIDTH,
        height: IMAGE_WIDTH,
        fit: BoxFit.cover,
        placeholder: (context, url) => CircularProgressIndicator(),
      );
    }

    Widget followBtn =
        Selector<ContactListProvider, bool>(builder: (context, exist, child) {
      IconData iconData = Icons.star_border;
      Color? color;
      if (exist) {
        iconData = Icons.star;
        color = Colors.yellow;
      }

      return GestureDetector(
        onTap: () {
          if (exist) {
            contactListProvider.removeCommunity(widget.info.aId.toAString());
          } else {
            contactListProvider.addCommunity(widget.info.aId.toAString());
          }
        },
        child: Container(
          margin: const EdgeInsets.only(
            left: Base.BASE_PADDING_HALF,
            right: Base.BASE_PADDING_HALF,
          ),
          child: Icon(
            iconData,
            color: color,
          ),
        ),
      );
    }, selector: (context, _provider) {
      return _provider.containCommunity(widget.info.aId.toAString());
    });

    List<Widget> list = [
      Container(
        margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        child: Row(
          children: [
            Container(
              alignment: Alignment.center,
              height: IMAGE_WIDTH,
              width: IMAGE_WIDTH,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
                color: themeData.hintColor,
              ),
              child: imageWidget,
            ),
            Container(
              margin: const EdgeInsets.only(
                left: Base.BASE_PADDING,
              ),
              child: Text(
                widget.info.aId.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            followBtn,
          ],
        ),
      ),
    ];

    list.add(ContentComponent(
      content: widget.info.description,
      event: widget.info.event,
    ));

    return Container(
      decoration: BoxDecoration(color: cardColor),
      padding: EdgeInsets.all(Base.BASE_PADDING),
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }
}
