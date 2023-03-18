import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostrmo/client/dm_session.dart';
import 'package:nostrmo/client/nip04/nip04.dart';
import 'package:nostrmo/component/name_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:pointycastle/export.dart' as pointycastle;

import '../../util/string_util.dart';

class DMSessionListItemComponent extends StatefulWidget {
  DMSession dmSession;

  pointycastle.ECDHBasicAgreement agreement;

  DMSessionListItemComponent({
    required this.dmSession,
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
        var hintColor = themeData.hintColor;
        var maxWidth = MediaQuery.of(context).size.width;
        var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

        var dmSession = widget.dmSession;

        var content = NIP04.decrypt(
            dmSession.newestEvent!.content, widget.agreement, dmSession.pubkey);

        Widget? imageWidget;
        if (metadata != null && StringUtil.isNotBlank(metadata.picture)) {
          imageWidget = CachedNetworkImage(
            imageUrl: metadata.picture!,
            width: IMAGE_WIDTH,
            height: IMAGE_WIDTH,
            fit: BoxFit.cover,
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => Icon(Icons.error),
          );
        }

        var leftWidget = Container(
          alignment: Alignment.center,
          height: IMAGE_WIDTH,
          width: IMAGE_WIDTH,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HALF_IMAGE_WIDTH),
            color: Colors.grey,
          ),
          child: imageWidget,
        );

        var lastEvent = widget.dmSession.newestEvent!;

        return Container(
          padding: EdgeInsets.all(Base.BASE_PADDING),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
            width: 1,
            color: hintColor,
          ))),
          child: Row(
            children: [
              leftWidget,
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(
                    left: Base.BASE_PADDING,
                    right: Base.BASE_PADDING,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          NameComponnet(
                            pubkey: widget.dmSession.pubkey,
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
                        margin: EdgeInsets.only(top: 2),
                        child: Text(
                          StringUtil.breakWord(content),
                          style: TextStyle(
                            fontSize: smallTextSize,
                            color: themeData.hintColor,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
        return _provider.getMetadata(widget.dmSession.pubkey);
      },
    );

    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.DM_DETAIL, widget.dmSession);
      },
      child: main,
    );
  }
}
