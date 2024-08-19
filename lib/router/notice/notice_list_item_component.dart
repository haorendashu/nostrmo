import 'package:flutter/material.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:nostrmo/provider/notice_provider.dart';

import '../../consts/base.dart';
import 'package:nostr_sdk/utils/string_util.dart';

class NoticeListItemComponent extends StatelessWidget {
  NoticeData notice;

  NoticeListItemComponent({required this.notice});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    return Container(
      padding: EdgeInsets.all(Base.BASE_PADDING),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
        width: 1,
        color: hintColor,
      ))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                StringUtil.breakWord(notice.url),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    GetTimeAgo.parse(DateTime.fromMillisecondsSinceEpoch(
                        notice.dateTime.millisecondsSinceEpoch)),
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
              StringUtil.breakWord(notice.content),
              style: TextStyle(
                fontSize: smallTextSize,
                color: themeData.hintColor,
                // overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
