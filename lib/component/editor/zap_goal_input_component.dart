import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';

class ZapGoalInputController {
  TextEditingController goalAmountController = TextEditingController();

  void clear() {
    goalAmountController.clear();
  }

  List<List<dynamic>> getTags() {
    List<List<dynamic>> tags = [];
    if (StringUtil.isNotBlank(goalAmountController.text)) {
      tags.add(["amount", goalAmountController.text]);
    }

    return tags;
  }

  bool checkInput(BuildContext context) {
    print("goal input call");
    var s = S.of(context);
    if (StringUtil.isBlank(goalAmountController.text)) {
      print("checked is blank!");
      BotToast.showText(text: s.Input_can_not_be_null);
      return false;
    }
    if (StringUtil.isNotBlank(goalAmountController.text)) {
      var num = int.tryParse(goalAmountController.text);
      if (num == null) {
        BotToast.showText(text: s.Number_parse_error);
        return false;
      }
    }

    return true;
  }
}

class ZapGoalInputComponent extends StatefulWidget {
  ZapGoalInputController zapGoalInputController;

  ZapGoalInputComponent({required this.zapGoalInputController});

  @override
  State<StatefulWidget> createState() {
    return _ZapGoalInputComponent();
  }
}

class _ZapGoalInputComponent extends State<ZapGoalInputComponent> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    List<Widget> list = [];

    Widget inputWidget = TextField(
      controller: widget.zapGoalInputController.goalAmountController,
      decoration: InputDecoration(
        hintText: s.Goal_Amount_In_Sats,
      ),
    );

    list.add(Container(
      child: inputWidget,
    ));

    return Container(
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        bottom: Base.BASE_PADDING,
      ),
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }
}
