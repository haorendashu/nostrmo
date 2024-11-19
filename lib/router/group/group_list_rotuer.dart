import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/router/group/group_add_dialog.dart';
import 'package:nostrmo/router/group/group_list_item_component.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../generated/l10n.dart';

class GroupListRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GroupListRouter();
  }
}

class _GroupListRouter extends State<GroupListRouter> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var s = S.of(context);
    var appbarColor = themeData.appBarTheme.titleTextStyle!.color;

    var main = Selector<ListProvider, List<GroupIdentifier>>(
      builder: (context, list, child) {
        return ListView.builder(itemBuilder: (context, index) {
          if (list.length <= index) {
            return null;
          }

          var groupIdentifier = list[index];
          return GestureDetector(
            onTap: () {
              RouterUtil.router(
                  context, RouterPath.GROUP_DETAIL, groupIdentifier);
            },
            child: Container(
              margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
              child: GroupListItemComponent(groupIdentifier),
            ),
          );
        });
      },
      selector: (context, _provider) {
        return _provider.groupIdentifiers;
      },
      shouldRebuild: (l1, l2) {
        return true;
      },
    );

    return Scaffold(
      floatingActionButton: TextButton(
        onPressed: () {
          groupAdd();
        },
        style: ButtonStyle(),
        child: Text(
          "+",
          style: TextStyle(
            color: appbarColor,
            fontSize: 30,
          ),
        ),
      ),
      body: main,
    );
  }

  void groupAdd() {
    GroupAddDailog.show(context);
  }
}
