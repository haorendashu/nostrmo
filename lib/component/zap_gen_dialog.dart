import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/client/event.dart';

import '../client/zap/zap_action.dart';
import '../consts/base.dart';
import '../generated/l10n.dart';
import '../util/router_util.dart';
import '../util/string_util.dart';

class ZapGenDialog extends StatefulWidget {
  String pubkey;

  String? eventId;

  ZapGenDialog({required this.pubkey, this.eventId});

  static Future<void> show(BuildContext context, String pubkey,
      {String? eventId}) async {
    return await showDialog<void>(
      context: context,
      builder: (_context) {
        return ZapGenDialog(
          pubkey: pubkey,
          eventId: eventId,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _ZapGenDialog();
  }
}

class _ZapGenDialog extends State<ZapGenDialog> {
  late TextEditingController controller;
  late TextEditingController commentController;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    commentController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;
    var titleFontSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];

    list.add(Container(
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING),
      child: Text(
        s.Input_Sats_num,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: titleFontSize,
        ),
      ),
    ));

    list.add(Container(
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 1,
        autofocus: true,
        decoration: InputDecoration(
          hintText: s.Input_Sats_num,
          border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    list.add(Container(
      child: TextField(
        controller: commentController,
        minLines: 1,
        maxLines: 1,
        autofocus: true,
        decoration: InputDecoration(
          hintText: "${s.Input_Comment} (${s.Optional})",
          border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    // list.add(Expanded(child: Container()));

    list.add(Container(
      margin: EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: 6,
      ),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: () {
            _onComfirm();
          },
          highlightColor: mainColor.withOpacity(0.2),
          child: Container(
            color: mainColor,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              S.of(context).Comfirm,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ));

    var main = Container(
      padding: EdgeInsets.all(Base.BASE_PADDING),
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
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            // height: double.infinity,
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

  Future<void> _onComfirm() async {
    var text = controller.text;
    var num = int.tryParse(text);
    if (num == null) {
      BotToast.showText(text: S.of(context).Number_parse_error);
      return;
    }

    var comment = commentController.text;
    RouterUtil.back(context);

    await ZapAction.handleZap(context, num, widget.pubkey,
        eventId: widget.eventId, comment: comment);
  }
}
