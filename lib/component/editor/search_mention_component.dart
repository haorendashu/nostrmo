import 'package:flutter/material.dart';

import '../../data/metadata.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/string_util.dart';
import '../../util/when_stop_function.dart';

typedef ResultBuildFunc = Widget Function();

typedef HandleSearchFunc = void Function(String);

class SaerchMentionComponent extends StatefulWidget {
  ResultBuildFunc resultBuildFunc;

  HandleSearchFunc handleSearchFunc;

  SaerchMentionComponent({
    required this.resultBuildFunc,
    required this.handleSearchFunc,
  });

  @override
  State<StatefulWidget> createState() {
    return _SaerchMentionComponent();
  }
}

class _SaerchMentionComponent extends State<SaerchMentionComponent>
    with WhenStopFunction {
  TextEditingController controller = TextEditingController();

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      var hasText = StringUtil.isNotBlank(controller.text);
      if (!showSuffix && hasText) {
        setState(() {
          showSuffix = true;
        });
        return;
      } else if (showSuffix && !hasText) {
        setState(() {
          showSuffix = false;
        });
      }

      whenStop(checkInput);
    });
  }

  bool showSuffix = false;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var backgroundColor = themeData.scaffoldBackgroundColor;
    var s = S.of(context);
    List<Widget> list = [];

    Widget? suffixWidget;
    if (showSuffix) {
      suffixWidget = GestureDetector(
        onTap: () {
          controller.text = "";
        },
        child: Icon(Icons.close),
      );
    }
    list.add(Container(
      child: TextField(
        autofocus: true,
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: s.Please_input_search_content,
          suffixIcon: suffixWidget,
        ),
        onEditingComplete: checkInput,
      ),
    ));

    list.add(Expanded(
      child: Container(
        color: backgroundColor,
        child: widget.resultBuildFunc(),
      ),
    ));

    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }

  checkInput() {
    var text = controller.text;
    widget.handleSearchFunc(text);
  }
}
