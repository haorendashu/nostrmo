import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip29/group_admins.dart';
import 'package:nostrmo/client/nip29/group_identifier.dart';
import 'package:nostrmo/client/nip29/group_metadata.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/group_provider.dart';
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

    list.add(
        Selector<GroupProvider, GroupAdmins?>(builder: (context, value, child) {
      if (value == null || value.contains(nostr!.publicKey) == null) {
        return Container();
      }

      return GestureDetector(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.only(right: Base.BASE_PADDING),
          child: const Icon(Icons.people),
        ),
      );
    }, selector: (context, _provider) {
      return _provider.getAdmins(widget.groupIdentifier);
    }));

    list.add(
        Selector<GroupProvider, GroupAdmins?>(builder: (context, value, child) {
      if (value == null || value.contains(nostr!.publicKey) == null) {
        return Container();
      }

      return GestureDetector(
        onTap: () {},
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
    // GroupMetadata groupMetadata = GroupMetadata(
    //   name: "Test NIP29 Group",
    //   picture:
    //       "https://image.nostr.build/9cf7e57fee80522b05c14e13c24ec7332d1c4d567953ce87d5617520cbc5dbaf.jpg",
    //   about: "This is the group about.",
    // );
    // groupMetadataProvider.udpateMetadata(widget.groupIdentifier, groupMetadata);
  }
}
