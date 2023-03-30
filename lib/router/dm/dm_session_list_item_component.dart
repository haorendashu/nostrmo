import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostrmo/client/dm_session.dart';
import 'package:nostrmo/client/nip04/nip04.dart';
import 'package:nostrmo/component/name_component.dart';
import 'package:nostrmo/component/point_component.dart';
import 'package:nostrmo/component/user_pic_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/dm_provider.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:pointycastle/export.dart' as pointycastle;

import '../../util/string_util.dart';

class DMSessionListItemComponent extends StatefulWidget {
  DMSessionDetail detail;

  pointycastle.ECDHBasicAgreement agreement;

  DMSessionListItemComponent({
    required this.detail,
    required this.agreement,
  });

  @override
  State<StatefulWidget> createState() {
    return _DMSessionListItemComponent();
  }
}

class _DMSessionListItemComponent extends State<DMSessionListItemComponent> {
  static const double IMAGE_WIDTH = 34;

  static const double HALF_IMAGE_WIDTH = 17;

  @override
  Widget build(BuildContext context) {
    var main = Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        var themeData = Theme.of(context);
        var mainColor = themeData.primaryColor;
        var hintColor = themeData.hintColor;
        var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

        var dmSession = widget.detail.dmSession;

        var content = NIP04.decrypt(
            dmSession.newestEvent!.content, widget.agreement, dmSession.pubkey);
        content = content.replaceAll("\r", " ");
        content = content.replaceAll("\n", " ");

        var leftWidget = Container(
          margin: EdgeInsets.only(top: 4),
          child: UserPicComponent(
            pubkey: dmSession.pubkey,
            width: IMAGE_WIDTH,
          ),
        );

        var lastEvent = dmSession.newestEvent!;

        bool hasNewMessage = widget.detail.hasNewMessage();

        List<Widget> contentList = [
          Expanded(
            child: Text(
              StringUtil.breakWord(content),
              style: TextStyle(
                fontSize: smallTextSize,
                color: themeData.hintColor,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
        ];
        if (hasNewMessage) {
          contentList.add(Container(
            child: PointComponent(color: mainColor),
          ));
        }

        return Container(
          padding: EdgeInsets.all(Base.BASE_PADDING),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
            width: 1,
            color: hintColor,
          ))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leftWidget,
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(
                    left: Base.BASE_PADDING,
                    right: Base.BASE_PADDING,
                    top: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          NameComponnet(
                            pubkey: dmSession.pubkey,
                            metadata: metadata,
                          ),
                          Expanded(
                            child: Container(
                              alignment: Alignment.centerRight,
                              child: Text(
                                GetTimeAgo.parse(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        lastEvent.createdAt * 1000)),
                                style: TextStyle(
                                  fontSize: smallTextSize,
                                  color: themeData.hintColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        child: Row(children: contentList),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      selector: (context, _provider) {
        return _provider.getMetadata(widget.detail.dmSession.pubkey);
      },
    );

    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.DM_DETAIL, widget.detail);
      },
      child: main,
    );
  }
}
