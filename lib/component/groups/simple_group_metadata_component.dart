import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/nip29/group_metadata.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../provider/group_provider.dart';
import '../../util/router_util.dart';
import '../image_component.dart';

class SimpleGroupMetadataComponent extends StatefulWidget {
  GroupIdentifier groupIdentifier;

  SimpleGroupMetadataComponent(this.groupIdentifier);

  @override
  State<StatefulWidget> createState() {
    return _SimpleGroupMetadataComponent();
  }
}

class _SimpleGroupMetadataComponent
    extends State<SimpleGroupMetadataComponent> {
  double IMAGE_WIDTH = 16;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    Color? cardColor = themeData.cardColor;
    if (cardColor == Colors.white) {
      cardColor = Colors.grey[300];
    }
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;

    return Container(
      child: Selector<GroupProvider, GroupMetadata?>(builder:
          (BuildContext context, GroupMetadata? groupMetadata, Widget? child) {
        if (groupMetadata == null) {
          return Container();
        }

        List<Widget> list = [
          Icon(
            Icons.group,
            size: fontSize,
          ),
        ];

        list.add(Container(
          width: IMAGE_WIDTH,
          height: IMAGE_WIDTH,
          margin: const EdgeInsets.only(
            left: Base.BASE_PADDING_HALF,
            right: Base.BASE_PADDING_HALF,
          ),
          clipBehavior: Clip.hardEdge,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
            color: themeData.hintColor,
          ),
          child: groupMetadata.picture != null
              ? ImageComponent(
                  width: IMAGE_WIDTH,
                  height: IMAGE_WIDTH,
                  imageUrl: groupMetadata.picture!,
                  fit: BoxFit.fill,
                )
              : null,
        ));

        var name = groupMetadata.name ?? "Unknown Group";
        list.add(Container(
          child: Text(name),
        ));

        var main = Container(
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
            top: 2,
            bottom: 2,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: list,
          ),
        );

        return GestureDetector(
          onTap: () {
            RouterUtil.router(
                context, RouterPath.GROUP_CHAT, widget.groupIdentifier);
          },
          child: main,
        );
      }, selector: (context, _provider) {
        return _provider.getMetadata(widget.groupIdentifier);
      }),
    );
  }
}
