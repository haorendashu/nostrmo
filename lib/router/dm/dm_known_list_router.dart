import 'package:flutter/material.dart';
import 'package:nostrmo/provider/notice_provider.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:provider/provider.dart';

import '../../provider/dm_provider.dart';
import 'dm_notice_item_component.dart';
import 'dm_session_list_item_component.dart';

class DMKnownListRouter extends StatefulWidget {
  ECDHBasicAgreement agreement;

  DMKnownListRouter({required this.agreement});

  @override
  State<StatefulWidget> createState() {
    return _DMKnownListRouter();
  }
}

class _DMKnownListRouter extends State<DMKnownListRouter> {
  @override
  Widget build(BuildContext context) {
    var _dmProvider = Provider.of<DMProvider>(context);
    var details = _dmProvider.knownList;
    var allLength = details.length;

    var _noticeProvider = Provider.of<NoticeProvider>(context);
    var notices = _noticeProvider.notices;
    bool hasNewNotice = _noticeProvider.hasNewMessage();
    int flag = 0;
    if (notices.isNotEmpty) {
      allLength += 1;
      flag = 1;
    }

    return Container(
      child: ListView.builder(
        itemBuilder: (context, index) {
          if (index >= allLength) {
            return null;
          }

          if (index == 0 && flag > 0) {
            return DMNoticeItemComponent(
              newestNotice: notices.last,
              hasNewMessage: hasNewNotice,
            );
          } else {
            var detail = details[index - flag];
            return DMSessionListItemComponent(
              detail: detail,
              agreement: widget.agreement,
            );
          }
        },
        itemCount: allLength,
      ),
    );
  }
}
