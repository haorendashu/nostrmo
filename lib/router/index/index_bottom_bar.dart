import 'package:flutter/material.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../provider/setting_provider.dart';

class IndexBottomBar extends StatefulWidget {
  IndexBottomBar();

  @override
  State<StatefulWidget> createState() {
    return _IndexBottomBar();
  }
}

class _IndexBottomBar extends State<IndexBottomBar> {
  @override
  Widget build(BuildContext context) {
    var _indexProvider = Provider.of<IndexProvider>(context);
    var currentTap = _indexProvider.currentTap;

    List<Widget> list = [];

    int current = 0;

    list.add(IndexBottomBarButton(
      iconData: Icons.home,
      index: current,
      selected: current == currentTap,
      onDoubleTap: () {
        indexProvider.followScrollToTop();
      },
    ));
    current++;

    list.add(IndexBottomBarButton(
      iconData: Icons.search,
      index: current,
      selected: current == currentTap,
    ));
    current++;

    list.add(IndexBottomBarButton(
      iconData: Icons.mail,
      index: current,
      selected: current == currentTap,
    ));
    current++;

    list.add(IndexBottomBarButton(
      iconData: Icons.notifications, // notifications_active
      index: current,
      selected: current == currentTap,
    ));
    current++;

    return Container(
      width: double.infinity,
      child: Row(
        children: list,
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {}
}

class IndexBottomBarButton extends StatelessWidget {
  final IconData iconData;
  final int index;
  final bool selected;
  final Function(int)? onTap;
  Function? onDoubleTap;

  IndexBottomBarButton({
    required this.iconData,
    required this.index,
    required this.selected,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    // var settingProvider = Provider.of<SettingProvider>(context);
    // var bottomIconColor = settingProvider.bottomIconColor;

    Color? selectedColor = mainColor;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!(index);
          } else {
            indexProvider.setCurrentTap(index);
          }
        },
        onDoubleTap: () {
          if (onDoubleTap != null) {
            onDoubleTap!();
          }
        },
        child: Container(
          height: 50,
          child: Icon(
            iconData,
            color: selected ? selectedColor : null,
          ),
        ),
      ),
    );
  }
}
