import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip29/group_metadata.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/main.dart';

import '../../component/image_component.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';

class GroupSearchDialog extends StatefulWidget {
  String relayAddr;

  GroupSearchDialog(this.relayAddr);

  static Future<GroupMetadata?> show(
      BuildContext context, String relayAddr) async {
    return await showDialog<GroupMetadata>(
        context: context,
        useRootNavigator: false,
        builder: (_context) {
          return GroupSearchDialog(relayAddr);
        });
  }

  @override
  State<StatefulWidget> createState() {
    return _GroupSearchDialog();
  }
}

class _GroupSearchDialog extends CustState<GroupSearchDialog> {
  TextEditingController textController = TextEditingController();

  late S s;

  Map<String, GroupMetadata> groupMetadataMap = {};

  Map<String, int> groupIdTimeMap = {};

  int oldestCreatedTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  int queryLimit = 1000;

  int currentQueryEventCounter = 0;

  @override
  Future<void> onReady(BuildContext context) async {
    doQuery();
  }

  void doQuery({int? until}) {
    currentQueryEventCounter = 0;

    var filter = Filter(
      kinds: [EventKind.GROUP_METADATA],
      until: until,
      limit: queryLimit,
    );

    // print(filter.toJson());

    List<String> relays = [widget.relayAddr];

    nostr!.query(
      [filter.toJson()],
      onEvent,
      tempRelays: relays,
      targetRelays: relays,
      relayTypes: RelayType.NETWORK,
      onComplete: queryComplete,
    );

    textController.addListener(() {
      setState(() {});
    });
  }

  void onEvent(Event e) {
    currentQueryEventCounter++;
    // print(currentQueryEventCounter);
    if (oldestCreatedTime <= 0 || e.createdAt < oldestCreatedTime) {
      oldestCreatedTime = e.createdAt;
    }

    var metadata = GroupMetadata.loadFromEvent(e);
    if (metadata != null) {
      var time = groupIdTimeMap[metadata.groupId];
      if (time == null || e.createdAt > time) {
        if (StringUtil.isBlank(metadata.name)) {
          return;
        }

        groupIdTimeMap[metadata.groupId] = e.createdAt;
        groupMetadataMap[metadata.groupId] = metadata;
        setState(() {});
      }
    }
  }

  void queryComplete() {
    if (disposed) {
      return;
    }

    // TODO There must be something wrong here, don't load more here.
    // if (currentQueryEventCounter > queryLimit * 2 / 3) {
    //   // there maybe still some other events
    //   doQuery(until: oldestCreatedTime);
    // }
  }

  @override
  Widget doBuild(BuildContext context) {
    s = S.of(context);
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;
    Color cardColor = themeData.cardColor;
    var hintColor = themeData.hintColor;

    List<Widget> list = [];

    list.add(Text(
      "${s.Search} ${widget.relayAddr}",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: titleFontSize,
      ),
    ));

    list.add(Container(
      margin: const EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING * 2,
      ),
      child: TextField(
        controller: textController,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    var searchText = textController.text;

    var it = groupMetadataMap.values;
    List<Widget> metadataWidgets = [];
    for (var metadata in it) {
      if (StringUtil.isBlank(searchText) ||
          (metadata.name != null && metadata.name!.contains(searchText)) ||
          metadata.about != null && metadata.about!.contains(searchText)) {
        metadataWidgets.add(GestureDetector(
          onTap: () {
            RouterUtil.back(context, metadata);
          },
          behavior: HitTestBehavior.translucent,
          child: GroupMetadataComponent(metadata),
        ));
      }
    }
    list.add(Expanded(
        child: Container(
      width: double.infinity,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: Base.BASE_PADDING,
          runSpacing: Base.BASE_PADDING,
          alignment: WrapAlignment.center,
          children: metadataWidgets,
        ),
      ),
    )));

    var main = Container(
      margin: EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }
}

class GroupMetadataComponent extends StatelessWidget {
  GroupMetadata groupMetadata;

  GroupMetadataComponent(this.groupMetadata);

  double imageWidth = 30;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);

    List<Widget> list = [];
    Widget imageWidget = Container(
      width: imageWidth,
      height: imageWidth,
    );

    if (StringUtil.isNotBlank(groupMetadata.picture)) {
      imageWidget = ImageComponent(
        width: imageWidth,
        height: imageWidth,
        imageUrl: groupMetadata.picture!,
        fit: BoxFit.fill,
      );
    }

    list.add(Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(right: Base.BASE_PADDING_HALF),
            child: Container(
              width: imageWidth,
              height: imageWidth,
              clipBehavior: Clip.hardEdge,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(imageWidth / 2),
              ),
              child: imageWidget,
            ),
          ),
          Expanded(
            child: Text(
              groupMetadata.name ?? "",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ));

    list.add(Container(
      child: Text(
        groupMetadata.about ?? "",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: themeData.textTheme.bodySmall!.fontSize,
        ),
      ),
    ));

    return Container(
      width: 200,
      decoration: BoxDecoration(
        border: Border.all(
          color: themeData.dividerColor,
        ),
        borderRadius: BorderRadius.circular(Base.BASE_PADDING),
      ),
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        top: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }
}
