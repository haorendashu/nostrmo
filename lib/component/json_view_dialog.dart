import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:nostr_sdk/utils/platform_util.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../main.dart';
import '../util/router_util.dart';
import '../util/table_mode_util.dart';
import '../util/theme_util.dart';

class JsonViewDialog extends StatefulWidget {
  String jsonText;

  JsonViewDialog(this.jsonText);

  static Future<bool?> show(BuildContext context, String jsonText) async {
    return await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (_context) {
        return JsonViewDialog(
          jsonText,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _JsonViewDialog();
  }
}

class _JsonViewDialog extends State<JsonViewDialog> {
  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    var mainColor = themeData.primaryColor;
    var maxHeight = mediaDataCache.size.height;
    var textColor = themeData.textTheme.bodyMedium!.color;

    List<Widget> list = [];
    list.add(Expanded(
      child: Container(
        margin: const EdgeInsets.only(
          top: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING_HALF,
          left: Base.BASE_PADDING_HALF,
          right: Base.BASE_PADDING_HALF,
        ),
        child: JsonView.string(
          widget.jsonText,
          theme: JsonViewTheme(
            viewType: JsonViewType.collapsible,
            defaultTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            closeIcon: Icon(
              Icons.arrow_drop_up,
              size: 18,
              color: textColor,
            ),
            openIcon: Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: textColor,
            ),
            backgroundColor: cardColor,
          ),
        ),
      ),
    ));
    list.add(Container(
      margin: const EdgeInsets.only(
        left: Base.BASE_PADDING_HALF,
        right: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      child: Ink(
        decoration: BoxDecoration(color: mainColor),
        child: InkWell(
          onTap: () {
            _doCopy(widget.jsonText);
            RouterUtil.back(context);
          },
          highlightColor: mainColor.withOpacity(0.2),
          child: Container(
            color: mainColor,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              S.of(context).Copy,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ));

    var main = Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight * 0.8,
      ),
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        color: cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );

    if (PlatformUtil.isPC() || TableModeUtil.isTableMode()) {
      main = Container(
        width: mediaDataCache.size.width / 2,
        child: main,
      );
    }

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

  void _doCopy(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      BotToast.showText(text: S.of(context).Copy_success);
    });
  }
}
