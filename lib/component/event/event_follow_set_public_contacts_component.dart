import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip02/contact.dart';
import 'package:nostr_sdk/nip51/follow_set.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../data/metadata.dart';
import '../../generated/l10n.dart';
import '../../provider/metadata_provider.dart';
import '../../util/router_util.dart';
import '../user/name_component.dart';
import '../user/simple_metadata_component.dart';
import '../user/user_pic_component.dart';

class EventFollowSetPublicContactsComponent extends StatefulWidget {
  FollowSet followSet;

  String pubkey;

  EventFollowSetPublicContactsComponent(this.followSet, this.pubkey);

  @override
  State<StatefulWidget> createState() {
    return _EventFollowSetPublicContactsComponent();
  }
}

class _EventFollowSetPublicContactsComponent
    extends State<EventFollowSetPublicContactsComponent> {
  bool showMore = false;

  int defaultMacShown = 4;

  double OWNER_IMAGE_WIDTH = 20;

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    List<Widget> list = [];
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;

    list.add(Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
      if (metadata == null) {
        return Container();
      }

      List<Widget> titleList = [];
      titleList.add(GestureDetector(
        onTap: jumpToUserPage,
        child: Container(
          margin: const EdgeInsets.only(
            right: Base.BASE_PADDING_HALF,
          ),
          width: OWNER_IMAGE_WIDTH,
          height: OWNER_IMAGE_WIDTH,
          child: UserPicComponent(
            pubkey: widget.pubkey,
            width: OWNER_IMAGE_WIDTH,
            metadata: metadata,
          ),
        ),
      ));

      titleList.add(GestureDetector(
        onTap: jumpToUserPage,
        child: Container(
          margin: const EdgeInsets.only(
            left: Base.BASE_PADDING_HALF,
            right: Base.BASE_PADDING_HALF,
          ),
          child: NameComponent(
            pubkey: widget.pubkey,
            maxLines: 1,
            textOverflow: TextOverflow.ellipsis,
            metadata: metadata,
          ),
        ),
      ));

      titleList.add(Container(
        child: Text(
          "${S.of(context).Follow_set} ${widget.followSet.title != null ? ": ${widget.followSet.title}" : ""}",
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: Base.BASE_FONT_SIZE),
        padding: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: mainColor,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: titleList,
        ),
      );
    }, selector: (context, provider) {
      return provider.getMetadata(widget.pubkey);
    }));

    var contacts = widget.followSet.publicContacts;

    bool showShowMore = false;
    var length = contacts.length;
    if (length > defaultMacShown && !showMore) {
      length = defaultMacShown;
      showShowMore = true;
    }
    for (var i = 0; i < length; i++) {
      var contact = contacts[i];
      list.add(Container(
        margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            RouterUtil.router(context, RouterPath.USER, contact.publicKey);
          },
          child: SimpleMetadataComponent(
            pubkey: contact.publicKey,
          ),
        ),
      ));
    }

    if (showShowMore) {
      list.add(
        Container(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              setState(() {
                showMore = !showMore;
              });
            },
            child: Text(
              s.Show_more,
              style: TextStyle(
                color: mainColor,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }

  void jumpToUserPage() {
    RouterUtil.router(context, RouterPath.USER, widget.pubkey);
  }
}
