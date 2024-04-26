import 'package:flutter/material.dart';
import 'package:nostrmo/client/aid.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:provider/provider.dart';

import '../../client/nip02/cust_contact_list.dart';
import '../../component/appbar_back_btn_component.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/router_util.dart';

class FollowedCommunitiesRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FollowedCommunitiesRouter();
  }
}

class _FollowedCommunitiesRouter extends State<FollowedCommunitiesRouter> {
  CustContactList? contactList;

  @override
  Widget build(BuildContext context) {
    if (contactList == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null) {
        contactList = arg as CustContactList;
      }
    }
    if (contactList == null) {
      RouterUtil.back(context);
      return Container();
    }

    var s = S.of(context);
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var hintColor = themeData.hintColor;

    var communitiesList = contactList!.followedCommunitiesList().toList();

    var main = ListView.builder(
      itemBuilder: (context, index) {
        var id = AId.fromString(communitiesList[index]);
        if (id == null) {
          return Container();
        }

        var item = Container(
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
          ),
          child: Container(
              padding: const EdgeInsets.only(
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
                top: Base.BASE_PADDING,
                bottom: Base.BASE_PADDING,
              ),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                color: hintColor,
              ))),
              child: Row(children: [
                Text(id.title),
                Expanded(child: Container()),
                Selector<ContactListProvider, bool>(
                    builder: (context, exist, child) {
                  IconData iconData = Icons.star_border;
                  Color? color;
                  if (exist) {
                    iconData = Icons.star;
                    color = Colors.yellow;
                  }
                  return GestureDetector(
                    onTap: () {
                      if (exist) {
                        contactListProvider.removeCommunity(id.toAString());
                      } else {
                        contactListProvider.addCommunity(id.toAString());
                      }
                    },
                    child: Container(
                      margin:
                          const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                      child: Icon(
                        iconData,
                        color: color,
                      ),
                    ),
                  );
                }, selector: (context, _provider) {
                  return _provider.containCommunity(id.toAString());
                })
              ])),
        );

        return GestureDetector(
          onTap: () {
            RouterUtil.router(context, RouterPath.COMMUNITY_DETAIL, id);
          },
          child: item,
        );
      },
      itemCount: communitiesList.length,
    );

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          s.Followed_Communities,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        child: main,
      ),
    );
  }
}
