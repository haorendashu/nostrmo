import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip29/group_identifier.dart';
import 'package:nostrmo/component/user/name_component.dart';
import 'package:nostrmo/component/user/user_pic_component.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';

import '../../client/nip29/group_admins.dart';
import '../../component/appbar_back_btn_component.dart';
import '../../component/editor/search_mention_user_component.dart';
import '../../component/editor/text_input_and_search_dialog.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';

class GroupMembersRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GroupMembersRouter();
  }
}

class _GroupMembersRouter extends State<GroupMembersRouter> {
  GroupIdentifier? groupIdentifier;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    var s = S.of(context);

    var arg = RouterUtil.routerArgs(context);
    if (arg == null || arg is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }
    groupIdentifier = arg;

    bool isAdmin = false;
    var groupProvider = Provider.of<GroupProvider>(context);
    var groupMembers = groupProvider.getMembers(groupIdentifier!);
    var groupAdmins = groupProvider.getAdmins(groupIdentifier!);

    List<Widget> list = [];

    if (groupAdmins != null) {
      if (groupAdmins.contains(nostr!.publicKey) != null) {
        isAdmin = true;
      }

      list.add(buildHeader("Admins", bodyLargeFontSize!, null));
      for (var groupAdminUser in groupAdmins.users) {
        list.add(GroupMemberItemComponent(
            groupIdentifier!, groupAdminUser.pubkey!, isAdmin, groupAdminUser));
      }
    }
    if (groupMembers != null && groupMembers.members != null) {
      list.add(buildHeader(
          "Members", bodyLargeFontSize!, isAdmin ? addMember : null));
      for (var pubkey in groupMembers.members!) {
        list.add(
            GroupMemberItemComponent(groupIdentifier!, pubkey, isAdmin, null));
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          "Members",
          style: TextStyle(
            fontSize: bodyLargeFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: list,
      ),
    );
  }

  Widget buildHeader(String title, double fontSize, Function? addFunc) {
    List<Widget> list = [
      Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      )
    ];

    if (addFunc != null) {
      list.add(Container(
        margin: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
        child: GestureDetector(
          onTap: () {
            addFunc();
          },
          child: const Icon(Icons.add),
        ),
      ));
    }

    return Container(
      margin: const EdgeInsets.only(
        left: 20,
        top: Base.BASE_PADDING,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: list,
      ),
    );
  }

  addMember() async {
    var s = S.of(context);
    var value = await TextInputAndSearchDialog.show(
      context,
      s.Search,
      s.Please_input_user_pubkey,
      SearchMentionUserComponent(),
      hintText: s.User_Pubkey,
    );
    if (StringUtil.isNotBlank(value)) {
      groupProvider.addMember(groupIdentifier!, value!);
    }
  }
}

class GroupMemberItemComponent extends StatefulWidget {
  final GroupIdentifier groupIdentifier;

  final String pubkey;

  final bool isAdmin;

  GroupAdminUser? groupAdminUser;

  GroupMemberItemComponent(
      this.groupIdentifier, this.pubkey, this.isAdmin, this.groupAdminUser,
      {super.key});

  @override
  State<StatefulWidget> createState() {
    return _GroupMemberItemComponent();
  }
}

class _GroupMemberItemComponent extends State<GroupMemberItemComponent> {
  static double USER_PIC_WIDTH = 30;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    List<Widget> list = [];
    list.add(Container(
      margin: const EdgeInsets.only(right: Base.BASE_PADDING_HALF),
      child: UserPicComponent(pubkey: widget.pubkey, width: USER_PIC_WIDTH),
    ));
    list.add(NameComponent(pubkey: widget.pubkey));

    list.add(Expanded(child: Container()));

    if (widget.isAdmin) {
      list.add(GestureDetector(
        onTap: doDeleteMember,
        child: const Icon(
          Icons.delete,
          color: Colors.red,
        ),
      ));
    }

    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.USER, widget.pubkey);
      },
      child: Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.only(top: Base.BASE_PADDING),
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
          top: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
        ),
        color: cardColor,
        child: Row(
          children: list,
        ),
      ),
    );
  }

  void doDeleteMember() {
    groupProvider.removeMember(widget.groupIdentifier, widget.pubkey);
  }
}
