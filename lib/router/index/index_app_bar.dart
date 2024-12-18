import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../component/user/user_pic_component.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/relay_provider.dart';
import '../../util/router_util.dart';
import '../../util/table_mode_util.dart';

@deprecated
class IndexAppBar extends StatefulWidget implements PreferredSizeWidget {
  static const double height = 56;

  static Size size = const Size.fromHeight(height);

  Widget? center;

  IndexAppBar({this.center});

  @override
  State<StatefulWidget> createState() {
    return _IndexAppBar();
  }

  Size get preferredSize {
    return size;
  }
}

class _IndexAppBar extends State<IndexAppBar> {
  double picHeight = 30;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var paddingTop = mediaDataCache.padding.top;
    var textColor = themeData.appBarTheme.titleTextStyle!.color;
    var appBarBackgroundColor = themeData.appBarTheme.backgroundColor;

    Widget? userPicWidget;
    if (!TableModeUtil.isTableMode()) {
      userPicWidget = GestureDetector(
        onTap: () {
          Scaffold.of(context).openDrawer();
        },
        child: UserPicComponent(
          pubkey: nostr!.publicKey,
          width: picHeight,
        ),
      );
    } else {
      userPicWidget = Container(
        width: picHeight,
      );
    }

    var center = widget.center;
    center ??= Container();

    var rightWidget =
        Selector<RelayProvider, String>(builder: (context, relayNum, child) {
      return Text(
        relayNum,
        style: TextStyle(color: textColor),
      );
    }, selector: (context, _provider) {
      return _provider.relayNumStr();
    });

    return Container(
      padding: EdgeInsets.only(
        top: paddingTop,
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      height: paddingTop + IndexAppBar.height,
      decoration: BoxDecoration(
        color: appBarBackgroundColor,
        border: Border(
          bottom:
              BorderSide(width: 1, color: themeData.scaffoldBackgroundColor),
        ),
      ),
      child: Row(children: [
        Container(
          child: userPicWidget,
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            child: center,
          ),
        ),
        GestureDetector(
          onTap: () {
            RouterUtil.router(context, RouterPath.RELAYS);
          },
          child: rightWidget,
        ),
      ]),
    );
  }
}
