import 'package:flutter/material.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/contact_list_provider.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';

import '../../client/nip51/follow_set.dart';
import '../../component/editor/text_input_dialog.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';

class FollowSetListRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FollowSetListRouter();
  }
}

class _FollowSetListRouter extends CustState<FollowSetListRouter> {
  @override
  Widget doBuild(BuildContext context) {
    var s = S.of(context);

    var themeData = Theme.of(context);
    var textColor = themeData.textTheme.bodyMedium!.color;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;

    var main = Selector<ContactListProvider, Map<String, FollowSet>>(
        builder: (context, map, child) {
      var followSets = map.values;
      var followSetList = followSets.toList();
      return ListView.builder(
        itemBuilder: (context, index) {
          var followSet = followSetList[index];
          return Container(
            margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
            child: GestureDetector(
              onTap: () {
                RouterUtil.router(
                    context, RouterPath.FOLLOW_SET_DETAIL, followSet);
              },
              child: FollowSetListItem(followSet, () {
                setState(() {});
              }),
            ),
          );
        },
        itemCount: followSetList.length,
      );
    }, selector: (context, provider) {
      return provider.followSetMap;
    });

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: themeData.appBarTheme.titleTextStyle!.color,
          ),
        ),
        title: Text(
          s.Follow_set,
          style: TextStyle(
            fontSize: largeTextSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            child: TextButton(
              onPressed: followSetAdd,
              style: ButtonStyle(),
              child: Text(
                "+",
                style: TextStyle(
                  color: textColor,
                  fontSize: 30,
                ),
              ),
            ),
          ),
        ],
      ),
      body: main,
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {}

  Future<void> followSetAdd() async {
    // edit title
    var text = await TextInputDialog.show(
      context,
      S.of(context).Input_follow_set_name,
      value: "",
    );
    if (StringUtil.isNotBlank(text)) {
      FollowSet fs = FollowSet(StringUtil.rndNameStr(16), {}, {}, {}, {}, {},
          {}, {}, {}, {}, DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: text);
      contactListProvider.addFollowSet(fs);
      setState(() {});
    }
  }
}

class FollowSetListItem extends StatelessWidget {
  late S s;

  FollowSet followSet;

  Function listUIUpdate;

  FollowSetListItem(this.followSet, this.listUIUpdate);

  @override
  Widget build(BuildContext context) {
    s = S.of(context);
    var themeData = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      color: themeData.cardColor,
      child: Row(
        children: [
          Expanded(child: Text(followSet.displayName())),
          Container(
            margin: EdgeInsets.only(right: Base.BASE_PADDING),
            child: Row(
              children: [
                Container(
                  margin: EdgeInsets.only(right: Base.BASE_PADDING_HALF),
                  child: Icon(Icons.people),
                ),
                Text(
                    "${followSet.privateContacts.length} / ${followSet.publicContacts.length}")
              ],
            ),
          ),
          PopupMenuButton(
            tooltip: s.More,
            itemBuilder: (context) {
              List<PopupMenuItem> list = [
                PopupMenuItem(
                  value: "editTitle",
                  child: Row(
                    children: [Icon(Icons.edit), Text(" ${s.Edit_name}")],
                  ),
                ),
                PopupMenuItem(
                  value: "delete",
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      Text(
                        " ${s.Delete}",
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ];

              return list;
            },
            child: Icon(Icons.menu),
            onSelected: (value) {
              onSelect(context, value);
            },
          ),
        ],
      ),
    );
  }

  Future<void> titleEdit(BuildContext context) async {
    // edit title
    var text = await TextInputDialog.show(
      context,
      S.of(context).Follow_set_name_edit,
      value: followSet.title,
    );
    if (StringUtil.isNotBlank(text)) {
      followSet.title = text;
      contactListProvider.addFollowSet(followSet);
    }

    listUIUpdate();
  }

  void doDelete() {
    contactListProvider.deleteFollowSet(followSet.dTag);
    listUIUpdate();
  }

  void onSelect(BuildContext context, value) {
    if (value == "editTitle") {
      titleEdit(context);
    } else if (value == "delete") {
      doDelete();
    }
  }
}
