import 'package:flutter/material.dart';
import 'package:nostrmo/component/user/metadata_top_component.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_util.dart';

import '../../client/event_relation.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../zap_split_icon_component.dart';
import 'search_mention_user_component.dart';
import 'text_input_and_search_dialog.dart';
import 'zap_split_input_item_component.dart';

class ZapSplitInputComponent extends StatefulWidget {
  List<EventZapInfo> eventZapInfos;

  ZapSplitInputComponent(
    this.eventZapInfos,
  );

  @override
  State<StatefulWidget> createState() {
    return _ZapSplitInputComponent();
  }
}

class _ZapSplitInputComponent extends State<ZapSplitInputComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize!;
    var hintColor = themeData.hintColor;
    var s = S.of(context);

    List<Widget> list = [];
    list.add(Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.only(right: Base.BASE_PADDING_HALF),
            child: ZapSplitIconComponent(titleFontSize + 2),
          ),
          Text(
            s.Split_and_Transfer_Zap,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(child: Container()),
          MetadataTextBtn(text: s.Add_User, onTap: addUser),
        ],
      ),
    ));

    list.add(Divider());

    list.add(Container(
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      child: Text(
        s.Split_Zap_Tip,
        style: TextStyle(
          color: themeData.hintColor,
        ),
      ),
    ));

    for (var zapInfo in widget.eventZapInfos) {
      list.add(Container(
        margin: EdgeInsets.only(top: Base.BASE_PADDING_HALF),
        child: ZapSplitInputItemComponent(
          zapInfo,
          recountWeightAndRefresh,
        ),
      ));
    }

    return Container(
      // color: Colors.red,
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }

  Future<void> addUser() async {
    var s = S.of(context);
    var pubkey = await TextInputAndSearchDialog.show(
      context,
      s.Search,
      s.Please_input_user_pubkey,
      SearchMentionUserComponent(),
      hintText: s.User_Pubkey,
    );

    if (StringUtil.isNotBlank(pubkey)) {
      String relay = "";
      var relayListMetadata = metadataProvider.getRelayListMetadata(pubkey!);
      if (relayListMetadata != null &&
          relayListMetadata.writeAbleRelays.isNotEmpty) {
        relay = relayListMetadata.writeAbleRelays.first;
      }

      widget.eventZapInfos.add(EventZapInfo(pubkey, relay, 0.5));
      recountWeightAndRefresh();
    }
  }

  void recountWeightAndRefresh() {
    double totalWeight = 0;
    for (var zapInfo in widget.eventZapInfos) {
      totalWeight += zapInfo.weight;
    }

    for (var zapInfo in widget.eventZapInfos) {
      zapInfo.weight =
          double.parse((zapInfo.weight / totalWeight).toStringAsFixed(2));
    }

    setState(() {});
  }
}
