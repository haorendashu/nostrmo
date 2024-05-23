import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostrmo/component/emoji_picker_component.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../router/index/index_drawer_content.dart';
import '../util/platform_util.dart';
import '../util/router_util.dart';
import '../util/theme_util.dart';

class LikeTextSelectBottomSheet extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LikeTextSelectBottomSheet();
  }
}

class _LikeTextSelectBottomSheet extends State<LikeTextSelectBottomSheet> {
  @override
  Widget build(BuildContext context) {
    var s = S.of(context);

    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;
    var backgroundColor = themeData.scaffoldBackgroundColor;

    List<Widget> list = [];
    list.add(Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: hintColor,
          ),
        ),
      ),
      child: IndexDrawerItem(
        iconData: Icons.emoji_emotions_outlined,
        name: "Emoji",
        onTap: () {},
      ),
    ));

    list.add(EmojiPickerComponent((emoji) {
      RouterUtil.back(context, emoji);
    }));

    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }
}
