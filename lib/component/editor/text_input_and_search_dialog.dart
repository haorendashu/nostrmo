import 'package:flutter/material.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../router/index/index_app_bar.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';
import 'search_mention_user_component.dart';
import 'text_input_dialog_inner_component.dart';

class TextInputAndSearchDialog extends StatefulWidget {
  String searchTabName;

  String title;

  String? hintText;

  String? value;

  Widget searchWidget;

  bool Function(BuildContext, String)? valueCheck;

  TextInputAndSearchDialog(
    this.searchTabName,
    this.title,
    this.searchWidget, {
    this.hintText,
    this.value,
    this.valueCheck,
  });

  static Future<String?> show(BuildContext context, String searchTabName,
      String title, Widget searchWidget,
      {String? value,
      String? hintText,
      bool Function(BuildContext, String)? valueCheck}) async {
    return await showDialog<String>(
        context: context,
        builder: (_context) {
          return TextInputAndSearchDialog(
            searchTabName,
            StringUtil.breakWord(title),
            searchWidget,
            hintText: hintText,
            value: value,
            valueCheck: valueCheck,
          );
        });
  }

  @override
  State<StatefulWidget> createState() {
    return _TextInputAndSearchDialog();
  }
}

class _TextInputAndSearchDialog extends State<TextInputAndSearchDialog>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(initialIndex: 0, length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var cardColro = themeData.cardColor;
    var mainColor = themeData.primaryColor;

    var textInputWidget = TextInputDialogInnerComponent(
      widget.title,
      hintText: widget.hintText,
      value: widget.value,
      valueCheck: widget.valueCheck,
    );

    List<Widget> list = [];
    list.add(Container(
      color: mainColor,
      child: TabBar(
        tabs: [
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(widget.searchTabName),
          ),
          Container(
            height: IndexAppBar.height,
            alignment: Alignment.center,
            child: Text(
              s.Input,
              textAlign: TextAlign.center,
            ),
          ),
        ],
        controller: tabController,
      ),
    ));
    list.add(Container(
      height: 235,
      width: double.infinity,
      child: TabBarView(
        children: [
          widget.searchWidget,
          textInputWidget,
        ],
        controller: tabController,
      ),
    ));

    var main = Container(
      color: cardColro,
      child: Column(
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
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
