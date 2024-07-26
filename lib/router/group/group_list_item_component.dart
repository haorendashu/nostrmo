import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip29/group_admins.dart';
import 'package:nostrmo/client/nip29/group_identifier.dart';
import 'package:nostrmo/client/nip29/group_metadata.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';

class GroupListItemComponent extends StatefulWidget {
  final GroupIdentifier groupIdentifier;

  GroupListItemComponent(this.groupIdentifier);

  @override
  State<StatefulWidget> createState() {
    return _GroupListItemComponent();
  }
}

class _GroupListItemComponent extends State<GroupListItemComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    List<Widget> list = [];
    list.add(Expanded(
        child: Selector<GroupProvider, GroupMetadata?>(
      builder: (BuildContext context, GroupMetadata? value, Widget? child) {
        String text = widget.groupIdentifier.groupId;
        if (value != null && StringUtil.isNotBlank(value.name)) {
          text = value.name!;
        }

        return Text(text);
      },
      selector: (context, _provider) {
        return _provider.getMetadata(widget.groupIdentifier);
      },
    )));

    list.add(Selector<GroupProvider, int>(builder: (context, value, child) {
      if (value <= 0) {
        return Container();
      }

      return GestureDetector(
        onTap: editGroupMembers,
        child: Container(
          margin: const EdgeInsets.only(right: Base.BASE_PADDING),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [const Icon(Icons.people), Text(" $value")],
          ),
        ),
      );
    }, selector: (context, _provider) {
      var admins = _provider.getAdmins(widget.groupIdentifier);
      var members = _provider.getMembers(widget.groupIdentifier);
      return (admins != null ? admins.users.length : 0) +
          (members != null && members.members != null
              ? members.members!.length
              : 0);
    }));

    list.add(
        Selector<GroupProvider, GroupAdmins?>(builder: (context, value, child) {
      if (value == null || value.contains(nostr!.publicKey) == null) {
        return Container();
      }

      return GestureDetector(
        onTap: editGroupMetadata,
        child: Container(
          margin: const EdgeInsets.only(right: Base.BASE_PADDING),
          child: const Icon(Icons.edit),
        ),
      );
    }, selector: (context, _provider) {
      return _provider.getAdmins(widget.groupIdentifier);
    }));

    list.add(GestureDetector(
      onTap: delGroup,
      child: const Icon(
        Icons.delete,
        color: Colors.red,
      ),
    ));

    return Container(
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      color: themeData.cardColor,
      child: Row(
        children: list,
      ),
    );
  }

  void delGroup() {
    listProvider.removeGroup(widget.groupIdentifier);
  }

  void editGroupMetadata() {
    RouterUtil.router(context, RouterPath.GROUP_EDIT, widget.groupIdentifier);
  }

  void editGroupMembers() {
    RouterUtil.router(
        context, RouterPath.GROUP_MEMBERS, widget.groupIdentifier);
  }
}
