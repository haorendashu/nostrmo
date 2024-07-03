import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/event_relation.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/zap/zaps_send_dialog.dart';
import 'package:nostrmo/generated/l10n.dart';

import '../../client/zap/zap_action.dart';
import '../../consts/base.dart';
import '../../main.dart';
import '../../util/router_util.dart';
import 'zap_bottom_sheet_user_component.dart';

class ZapBottomSheetComponent extends StatefulWidget {
  static void show(
      BuildContext context, Event event, EventRelation eventRelation) {
    List<EventZapInfo> list = [];
    var zapInfos = eventRelation.zapInfos;
    if (zapInfos.isEmpty) {
      String relayAddr = "";
      var relayListMetadata =
          metadataProvider.getRelayListMetadata(event.pubkey);
      if (relayListMetadata != null &&
          relayListMetadata.writeAbleRelays.isNotEmpty) {
        relayAddr = relayListMetadata.writeAbleRelays.first;
      }
      list.add(EventZapInfo(event.pubkey, relayAddr, 1));
    } else {
      list.addAll(zapInfos);
    }

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext _context) {
        return ZapBottomSheetComponent(
          context,
          list,
          eventId: event.id,
        );
      },
    );
  }

  String? eventId;

  List<EventZapInfo> zapInfos;

  BuildContext parentContext;

  ZapBottomSheetComponent(
    this.parentContext,
    this.zapInfos, {
    this.eventId,
  });

  @override
  State<StatefulWidget> createState() {
    return _ZapBottomSheetComponent();
  }
}

class _ZapBottomSheetComponent extends CustState<ZapBottomSheetComponent> {
  late S s;

  Map<String, int> pubkeySendNum = {};

  @override
  Widget doBuild(BuildContext context) {
    s = S.of(context);
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;

    List<Widget> list = [];

    List<Widget> userWidgetList = [];
    bool configMaxWidth = false;
    if (widget.zapInfos.isNotEmpty) {
      configMaxWidth = true;
    }
    for (var zapInfo in widget.zapInfos) {
      userWidgetList.add(ZapBottomSheetUserComponent(
        zapInfo.pubkey,
        configMaxWidth: configMaxWidth,
      ));
    }
    list.add(Container(
      width: double.infinity,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(top: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: userWidgetList,
        ),
      ),
    ));

    list.add(Divider());

    List<Widget> numberWidgets = [];
    numberWidgets.add(wrapByBtn(s, Text("50"), value: 50));
    numberWidgets.add(wrapByBtn(s, Text("100"), value: 100));
    numberWidgets.add(wrapByBtn(s, Text("500"), value: 500));
    numberWidgets.add(wrapByBtn(s, Text("1k"), value: 1000));
    numberWidgets.add(wrapByBtn(s, Text("5k"), value: 5000));
    numberWidgets.add(wrapByBtn(
      s,
      Expanded(
          child: TextField(
        controller: numberController,
        autofocus: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
      )),
    ));
    list.add(Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING,
      ),
      child: Wrap(
        spacing: Base.BASE_PADDING,
        runSpacing: Base.BASE_PADDING_HALF,
        children: numberWidgets,
      ),
    ));

    list.add(Container(
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
        top: Base.BASE_PADDING_HALF,
      ),
      child: TextField(
        controller: msgController,
        decoration: InputDecoration(
          hintText: "${s.Input_Comment} (${s.Optional})",
          border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    list.add(Container(
      margin: EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: 20,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: () {
            _onConfirm();
          },
          highlightColor: mainColor.withOpacity(0.2),
          child: Container(
            color: mainColor,
            height: 50,
            alignment: Alignment.center,
            child: Text(
              S.of(context).Confirm,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ));

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        // height: 200,
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: list,
        ),
      ),
    );
  }

  TextEditingController numberController = TextEditingController();

  TextEditingController msgController = TextEditingController();

  int? zapNum = 100;

  Widget wrapByBtn(S s, Widget child, {int? value}) {
    var themeData = Theme.of(context);
    double width = 80;
    Color? borderColor = themeData.hintColor;
    var mainColor = themeData.primaryColor;
    if (value == zapNum) {
      borderColor = mainColor;
    }

    List<Widget> list = [];
    list.add(Container(
      child: Icon(
        Icons.bolt,
        fill: 0.5,
        color: Colors.orange,
        size: themeData.textTheme.bodyMedium!.fontSize,
      ),
    ));
    if (child is Text) {
      list.add(child);
    } else if (child is! Text) {
      if (zapNum == null) {
        list.add(child);
      } else {
        list.add(Text(
          s.Custom,
          style: TextStyle(
            fontSize: themeData.textTheme.bodySmall!.fontSize,
          ),
        ));
      }
    }
    list.add(Container(
      width: themeData.textTheme.bodyMedium!.fontSize! / 2,
    ));

    return GestureDetector(
      onTap: () {
        setState(() {
          zapNum = value;
        });
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: width,
        height: width,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: mainColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: list,
        ),
      ),
    );
  }

  Future<void> _onConfirm() async {
    var num = zapNum;
    if (num == null) {
      var text = numberController.text;
      num = int.tryParse(text);
      if (num == null) {
        BotToast.showText(text: S.of(context).Number_parse_error);
        return;
      }
    }

    var comment = msgController.text;
    RouterUtil.back(context);

    var zapInfosLength = widget.zapInfos.length;
    if (zapInfosLength == 1) {
      await ZapAction.handleZap(
          widget.parentContext, num, widget.zapInfos.first.pubkey,
          eventId: widget.eventId, comment: comment);
    } else {
      if (zapInfosLength > num) {
        BotToast.showText(text: s.Zap_number_not_enough);
        return;
      }

      double totalWeight = 0;
      for (var zapInfo in widget.zapInfos) {
        totalWeight += zapInfo.weight;
      }

      Map<String, int> pubkeyZapNumbers = {};
      for (var zapInfo in widget.zapInfos) {
        var zapNum = (zapInfo.weight / totalWeight * num).truncate();
        if (zapNum <= 0) {
          zapNum = 1;
        }

        pubkeyZapNumbers[zapInfo.pubkey] = zapNum;
      }

      RouterUtil.back(context);
      showDialog(
          context: widget.parentContext,
          builder: (context) {
            return ZapsSendDialog(
              zapInfos: widget.zapInfos,
              pubkeyZapNumbers: pubkeyZapNumbers,
              comment: comment,
            );
          });
    }
  }

  @override
  Future<void> onReady(BuildContext context) async {}
}
