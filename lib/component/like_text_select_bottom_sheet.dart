import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

    list.add(Container(
      height: 260,
      child: EmojiPicker(
        onEmojiSelected: (Category? category, Emoji emoji) {
          RouterUtil.back(context, emoji.emoji);
        },
        onBackspacePressed: null,
        // textEditingController:
        //     textEditionController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
        config: Config(
          columns: 10,
          emojiSizeMax: 20 * (PlatformUtil.isIOS() ? 1.30 : 1.0),
          verticalSpacing: 0,
          horizontalSpacing: 0,
          gridPadding: EdgeInsets.zero,
          initCategory: Category.RECENT,
          bgColor: backgroundColor,
          indicatorColor: mainColor,
          iconColor: Colors.grey,
          iconColorSelected: mainColor,
          backspaceColor: mainColor,
          skinToneDialogBgColor: Colors.white,
          skinToneIndicatorColor: Colors.grey,
          enableSkinTones: true,
          // showRecentsTab: true,
          recentTabBehavior: RecentTabBehavior.RECENT,
          recentsLimit: 30,
          emojiTextStyle:
              PlatformUtil.isWeb() ? GoogleFonts.notoColorEmoji() : null,
          noRecents: Text(
            'No Recents',
            style: TextStyle(fontSize: 14, color: Colors.black26),
            textAlign: TextAlign.center,
          ), // Needs to be const Widget
          loadingIndicator: const SizedBox.shrink(), // Needs to be const Widget
          tabIndicatorAnimDuration: kTabScrollDuration,
          categoryIcons: const CategoryIcons(),
          buttonMode: ButtonMode.MATERIAL,
        ),
      ),
    ));

    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    );
  }
}
