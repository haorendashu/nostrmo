import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../util/platform_util.dart';

class EmojiPickerComponent extends StatefulWidget {
  Function(String) onEmojiPick;

  EmojiPickerComponent(this.onEmojiPick);

  @override
  State<StatefulWidget> createState() {
    return _EmojiPickerComponent();
  }
}

class _EmojiPickerComponent extends State<EmojiPickerComponent> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var s = S.of(context);
    var mainColor = themeData.primaryColor;
    var bgColor = themeData.scaffoldBackgroundColor;

    return Container(
      height: 260,
      child: EmojiPicker(
        onEmojiSelected: (Category? category, Emoji emoji) {
          widget.onEmojiPick(emoji.emoji);
        },
        onBackspacePressed: null,
        // textEditingController:
        //     textEditionController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
        config: Config(
          emojiViewConfig: EmojiViewConfig(
            columns: 10,
            emojiSizeMax: 20 * (PlatformUtil.isIOS() ? 1.30 : 1.0),
            backgroundColor: bgColor,
          ),
          categoryViewConfig: CategoryViewConfig(
            tabBarHeight: 40.0,
            tabIndicatorAnimDuration: kTabScrollDuration,
            initCategory: Category.RECENT,
            recentTabBehavior: RecentTabBehavior.RECENT,
            showBackspaceButton: false,
            backgroundColor: bgColor,
            indicatorColor: mainColor,
            iconColor: Colors.grey,
            iconColorSelected: mainColor,
            backspaceColor: mainColor,
          ),
          bottomActionBarConfig: BottomActionBarConfig(
            enabled: true,
            showBackspaceButton: true,
            showSearchViewButton: true,
            backgroundColor: mainColor,
            buttonColor: mainColor,
            buttonIconColor: Colors.white,
            customBottomActionBar: (Config config, EmojiViewState state,
                VoidCallback showSearchView) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                child: Container(
                  color: config.bottomActionBarConfig.backgroundColor,
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: Base.BASE_PADDING),
                        height: 40,
                        child: Icon(
                          Icons.search,
                          color: config.bottomActionBarConfig.buttonIconColor,
                        ),
                      ),
                      Expanded(child: Container()),
                    ],
                  ),
                ),
                onTap: () {
                  showSearchView();
                },
              );
            },
          ),
          searchViewConfig: SearchViewConfig(
            backgroundColor: bgColor,
            hintText: s.Search,
          ),
        ),
      ),
    );
  }
}
