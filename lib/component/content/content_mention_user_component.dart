import 'package:flutter/material.dart';
import 'package:nostrmo/component/user/simple_name_component.dart';
import 'package:nostrmo/component/user/user_pic_component.dart';
import 'package:provider/provider.dart';

import '../../consts/router_path.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';
import '../../util/router_util.dart';
import '../user/name_component.dart';
import 'content_str_link_component.dart';

class ContentMentionUserComponent extends StatefulWidget {
  String pubkey;

  ContentMentionUserComponent({required this.pubkey});

  @override
  State<StatefulWidget> createState() {
    return _ContentMentionUserComponent();
  }
}

class _ContentMentionUserComponent extends State<ContentMentionUserComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    return Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        String name =
            SimpleNameComponent.getSimpleName(widget.pubkey, metadata);

        return ContentStrLinkComponent(
          str: "@$name",
          showUnderline: false,
          onTap: () {
            RouterUtil.router(context, RouterPath.USER, widget.pubkey);
          },
        );
      },
      selector: (context, _provider) {
        return _provider.getMetadata(widget.pubkey);
      },
    );

    // var mainColor = themeData.primaryColor;
    // var fontSize = themeData.textTheme.bodyMedium!.fontSize;

    // return Row(
    //   mainAxisSize: MainAxisSize.min,
    //   children: [
    //     Text(
    //       "@",
    //       style: TextStyle(
    //         color: mainColor,
    //         fontSize: fontSize! + 2,
    //       ),
    //     ),
    //     Container(
    //       margin: const EdgeInsets.only(left: 2, right: 2, top: 1),
    //       child: UserPicComponent(pubkey: widget.pubkey, width: fontSize - 3),
    //     ),
    //     Selector<MetadataProvider, Metadata?>(
    //       builder: (context, metadata, child) {
    //         return SimpleNameComponent(
    //           pubkey: widget.pubkey,
    //           metadata: metadata,
    //           textStyle: TextStyle(
    //             color: mainColor,
    //             fontSize: fontSize - 2,
    //           ),
    //         );
    //       },
    //       selector: (context, _provider) {
    //         return _provider.getMetadata(widget.pubkey);
    //       },
    //     ),
    //   ],
    // );
  }
}
