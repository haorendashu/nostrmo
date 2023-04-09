import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/filter_provider.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../util/string_util.dart';

class FilterDirtywordComponent extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FilterDirtywordComponent();
  }
}

class _FilterDirtywordComponent extends State<FilterDirtywordComponent> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var _filterProvider = Provider.of<FilterProvider>(context);
    var dirtywordList = _filterProvider.dirtywordList;

    List<Widget> list = [];
    for (var dirtyword in dirtywordList) {
      list.add(FilterDirtywordItemComponent(word: dirtyword));
    }

    return Container(
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.maxFinite,
              padding: EdgeInsets.all(Base.BASE_PADDING),
              child: Wrap(
                children: list,
                spacing: Base.BASE_PADDING,
                runSpacing: Base.BASE_PADDING,
              ),
            ),
          ),
          Container(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.abc),
                hintText: s.Input_dirtyword,
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: addDirtyWord,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void addDirtyWord() {
    var word = controller.text;
    word = word.trim();
    if (StringUtil.isBlank(word)) {
      BotToast.showText(text: S.of(context).Word_can_t_be_null);
      return;
    }

    filterProvider.addDirtyword(word);
    controller.clear();
    FocusScope.of(context).unfocus();
  }
}

class FilterDirtywordItemComponent extends StatefulWidget {
  String word;

  FilterDirtywordItemComponent({required this.word});

  @override
  State<StatefulWidget> createState() {
    return _FilterDirtywordItemComponent();
  }
}

class _FilterDirtywordItemComponent
    extends State<FilterDirtywordItemComponent> {
  bool showDel = false;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;
    var fontColor = themeData.appBarTheme.titleTextStyle!.color;

    List<Widget> list = [
      GestureDetector(
        onTap: () {
          setState(() {
            showDel = true;
          });
        },
        child: Container(
          padding: EdgeInsets.only(
            left: Base.BASE_PADDING_HALF,
            right: Base.BASE_PADDING_HALF,
            top: 4,
            bottom: 4,
          ),
          decoration: BoxDecoration(
            color: mainColor.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.word,
            style: TextStyle(
              color: fontColor,
            ),
          ),
        ),
      )
    ];

    if (showDel) {
      list.add(GestureDetector(
        onTap: () {
          filterProvider.removeDirtyword(widget.word);
        },
        child: Icon(
          Icons.delete,
          color: Colors.red,
        ),
      ));
    }

    return Stack(
      alignment: Alignment.center,
      children: list,
    );
  }
}
