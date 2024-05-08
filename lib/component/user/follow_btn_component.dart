import 'package:flutter/material.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../client/nip02/contact.dart';
import '../../main.dart';
import '../../provider/contact_list_provider.dart';
import '../follow_set_follow_bottom_sheet.dart';
import 'metadata_top_component.dart';

class FollowBtnComponent extends StatefulWidget {
  String pubkey;

  Color? borderColor;

  Color? followedBorderColor;

  FollowBtnComponent({
    required this.pubkey,
    this.borderColor,
    this.followedBorderColor,
  });

  @override
  State<StatefulWidget> createState() {
    return _FollowBtnComponent();
  }
}

class _FollowBtnComponent extends State<FollowBtnComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    return Selector<ContactListProvider, Contact?>(
      builder: (context, contact, child) {
        if (contact == null) {
          return MetadataTextBtn(
            text: "Follow",
            borderColor: widget.borderColor,
            onTap: () {
              contactListProvider.addContact(Contact(publicKey: widget.pubkey));
            },
            onLongPress: onFollowPress,
          );
        } else {
          return MetadataTextBtn(
            text: "Unfollow",
            borderColor: widget.followedBorderColor,
            onTap: () {
              contactListProvider.removeContact(widget.pubkey);
            },
            onLongPress: onFollowPress,
          );
        }
      },
      selector: (context, _provider) {
        return _provider.getContact(widget.pubkey);
      },
    );
  }

  void onFollowPress() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FollowSetFollowBottomSheet(widget.pubkey);
      },
    );
  }
}
