import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/data/custom_emoji.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/uploader.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';
import '../content/content_custom_emoji_component.dart';

class CustomEmojiAddDialog extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CustomEmojiAddDialog();
  }

  static Future<CustomEmoji?> show(BuildContext context) async {
    return await showDialog<CustomEmoji>(
      context: context,
      builder: (_context) {
        return CustomEmojiAddDialog();
      },
    );
  }
}

class _CustomEmojiAddDialog extends State<CustomEmojiAddDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
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
        s.Add_Custom_Emoji,
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
          hintText: s.Input_Custom_Emoji_Name,
          border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
        ),
      ),
    ));

    List<Widget> imageWidgetList = [
      GestureDetector(
        onTap: pickPicture,
        child: Icon(Icons.image),
      )
    ];
    if (StringUtil.isNotBlank(filepath)) {
      imageWidgetList.add(ContentCustomEmojiComponent(imagePath: filepath!));
    }

    list.add(Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: imageWidgetList,
    ));

    list.add(Container(
      margin: EdgeInsets.only(
        top: Base.BASE_PADDING,
        bottom: 6,
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
            height: 40,
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

  Future<void> pickPicture() async {
    filepath = await Uploader.pick(context);
    setState(() {});
  }

  static const _regExp = r"^[ZA-ZZa-z0-9_]+$";

  String? filepath;

  Future<void> _onConfirm() async {
    var s = S.of(context);
    var text = controller.text;
    if (StringUtil.isBlank(text)) {
      BotToast.showText(text: s.Input_can_not_be_null);
      return;
    }

    if (RegExp(_regExp).firstMatch(text) == null) {
      BotToast.showText(text: s.Input_parse_error);
      return;
    }

    var cancel = BotToast.showLoading();
    try {
      var imagePath = await Uploader.upload(
        filepath!,
        imageService: settingProvider.imageService,
      );
      log("$text $imagePath");

      if (StringUtil.isBlank(imagePath)) {
        BotToast.showText(text: s.Upload_fail);
        return;
      }

      filepath = imagePath;
    } finally {
      cancel.call();
    }

    RouterUtil.back(context, CustomEmoji(name: text, filepath: filepath));
  }
}
