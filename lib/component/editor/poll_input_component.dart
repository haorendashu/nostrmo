import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/util/string_util.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';

class PollInputController {
  TextEditingController minValueController = TextEditingController();
  TextEditingController maxValueController = TextEditingController();
  List<TextEditingController> pollOptionControllers = [];

  void clear() {
    minValueController.clear();
    maxValueController.clear();
    pollOptionControllers = [];
  }

  List<List<dynamic>> getTags() {
    List<List<dynamic>> tags = [];
    var length = pollOptionControllers.length;
    for (var i = 0; i < length; i++) {
      var pollPotion = pollOptionControllers[i];
      tags.add(["poll_option", "$i", pollPotion.text]);
    }
    if (StringUtil.isNotBlank(maxValueController.text)) {
      tags.add(["value_maximum", maxValueController.text]);
    }
    if (StringUtil.isNotBlank(minValueController.text)) {
      tags.add(["value_minimum", minValueController.text]);
    }

    return tags;
  }

  bool checkInput(BuildContext context) {
    var s = S.of(context);
    if (StringUtil.isNotBlank(maxValueController.text)) {
      var num = int.tryParse(maxValueController.text);
      if (num == null) {
        BotToast.showText(text: s.Number_parse_error);
        return false;
      }
    }
    if (StringUtil.isNotBlank(minValueController.text)) {
      var num = int.tryParse(minValueController.text);
      if (num == null) {
        BotToast.showText(text: s.Number_parse_error);
        return false;
      }
    }

    for (var pollOptionController in pollOptionControllers) {
      if (StringUtil.isBlank(pollOptionController.text)) {
        BotToast.showText(text: s.Input_can_not_be_null);
        return false;
      }
    }

    return true;
  }
}

class PollInputComponent extends StatefulWidget {
  PollInputController pollInputController;

  PollInputComponent({required this.pollInputController});

  @override
  State<StatefulWidget> createState() {
    return _PollInputComponent();
  }
}

class _PollInputComponent extends State<PollInputComponent> {
  @override
  void initState() {
    super.initState();

    widget.pollInputController.pollOptionControllers
        .add(TextEditingController());
    widget.pollInputController.pollOptionControllers
        .add(TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    List<Widget> list = [];

    bool delAble = false;
    if (widget.pollInputController.pollOptionControllers.length > 2) {
      delAble = true;
    }

    for (var controller in widget.pollInputController.pollOptionControllers) {
      Widget inputWidget = TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: s.poll_option_info,
        ),
      );
      if (delAble) {
        inputWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: inputWidget),
            IconButton(
                onPressed: () {
                  delPollOption(controller);
                },
                icon: Icon(Icons.delete)),
          ],
        );
      }

      list.add(Container(
        child: inputWidget,
      ));
    }

    list.add(Container(
      margin: EdgeInsets.only(top: Base.BASE_PADDING),
      child: InkWell(
        onTap: addPollOption,
        child: Container(
          height: 36,
          color: mainColor,
          alignment: Alignment.center,
          child: Text(
            s.add_poll_option,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ));

    list.add(Row(
      children: [
        Expanded(
            child: TextField(
          controller: widget.pollInputController.minValueController,
          decoration: InputDecoration(
            hintText: s.min_zap_num,
          ),
          keyboardType: TextInputType.number,
        )),
        Container(
          width: Base.BASE_PADDING,
        ),
        Expanded(
            child: TextField(
          controller: widget.pollInputController.maxValueController,
          decoration: InputDecoration(
            hintText: s.max_zap_num,
          ),
          keyboardType: TextInputType.number,
        )),
      ],
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

  void addPollOption() {
    widget.pollInputController.pollOptionControllers
        .add(TextEditingController());
    setState(() {});
  }

  void delPollOption(TextEditingController controller) {
    widget.pollInputController.pollOptionControllers.remove(controller);
    setState(() {});
  }
}
