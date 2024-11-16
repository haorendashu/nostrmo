import 'package:flutter/material.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:star_menu/star_menu.dart';

import '../consts/colors.dart';
import '../router/edit/editor_router.dart';
import '../router/media_edit/media_edit_router.dart';

class AddBtnWrapperComponent extends StatefulWidget {
  Widget child;

  AddBtnWrapperComponent({
    required this.child,
  });

  @override
  State<StatefulWidget> createState() {
    return _AddBtnWrapperComponent();
  }
}

class _AddBtnWrapperComponent extends State<AddBtnWrapperComponent> {
  StarMenuController starMenuController = StarMenuController();

  void closeMenu() {
    if (starMenuController.closeMenu != null) {
      starMenuController.closeMenu!();
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var iconSize = themeData.textTheme.bodyMedium!.fontSize;

    List<Widget> entries = [];
    var index = 0;

    entries.add(AddBtnStartItemButton(
      iconData: Icons.note,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: "Note",
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        EditorRouter.open(context);
      },
    ));
    entries.add(AddBtnStartItemButton(
      iconData: Icons.article,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: "Article",
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        EditorRouter.open(context, isLongForm: true);
      },
    ));
    entries.add(AddBtnStartItemButton(
      iconData: Icons.image,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: "Media",
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        MediaEditRouter.pickAndUpload(context);
      },
    ));
    entries.add(AddBtnStartItemButton(
      iconData: Icons.poll,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: "Poll",
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        EditorRouter.open(context, isPoll: true);
      },
    ));
    entries.add(AddBtnStartItemButton(
      iconData: Icons.trending_up,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: "Zap Goal",
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        EditorRouter.open(context, isZapGoal: true);
      },
    ));

    return Container(
      child: StarMenu(
        params: const StarMenuParameters(
          shape: MenuShape.linear,
          linearShapeParams: LinearShapeParams(
            alignment: LinearAlignment.left,
            space: Base.BASE_PADDING,
          ),
        ),
        controller: starMenuController,
        items: entries,
        child: widget.child,
      ),
    );
  }
}

class AddBtnStartItemButton extends StatelessWidget {
  IconData iconData;

  Color iconBackgroundColor;

  double? iconSize;

  String name;

  Color backgroundColor;

  Function onTap;

  AddBtnStartItemButton({
    required this.iconData,
    required this.iconBackgroundColor,
    this.iconSize,
    required this.name,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> list = [];
    list.add(Container(
      margin: const EdgeInsets.only(right: Base.BASE_PADDING_HALF),
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Icon(
        iconData,
        color: Colors.white,
        size: iconSize,
      ),
    ));
    list.add(Text(name));

    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.only(
          top: Base.BASE_PADDING_HALF,
          bottom: Base.BASE_PADDING_HALF,
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(2, 5),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: list,
        ),
      ),
    );
  }
}
