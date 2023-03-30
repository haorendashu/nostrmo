import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/notice_provider.dart';

import '../../component/point_component.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';

class DMNoticeItemComponent extends StatelessWidget {
  static const double IMAGE_WIDTH = 34;

  NoticeData newestNotice;

  bool hasNewMessage;

  DMNoticeItemComponent({
    required this.newestNotice,
    this.hasNewMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    var content = newestNotice.content;
    content = content.replaceAll("\r", " ");
    content = content.replaceAll("\n", " ");

    var leftWidget = Container(
      margin: EdgeInsets.only(top: 4),
      child: Container(
        width: IMAGE_WIDTH,
        height: IMAGE_WIDTH,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(IMAGE_WIDTH / 2),
          color: Colors.grey,
        ),
        child: Image.asset("assets/imgs/logo/logo512.png"),
      ),
    );

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

    var main = Container(
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
                      Text(
                        newestNotice.url,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerRight,
                          child: Text(
                            GetTimeAgo.parse(
                                DateTime.fromMillisecondsSinceEpoch(newestNotice
                                    .dateTime.millisecondsSinceEpoch)),
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

    return GestureDetector(
      onTap: () {
        noticeProvider.setRead();
        RouterUtil.router(context, RouterPath.NOTICES);
      },
      child: main,
    );
  }
}
