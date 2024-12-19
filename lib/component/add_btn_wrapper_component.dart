import 'package:flutter/material.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:star_menu/star_menu.dart';

import '../consts/colors.dart';
import '../generated/l10n.dart';
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

  static void addNote(BuildContext context) {
    EditorRouter.open(context);
  }

  static void addArticle(BuildContext context) {
    EditorRouter.open(context, isLongForm: true);
  }

  static void addMedia(BuildContext context) {
    MediaEditRouter.pickAndUpload(context);
  }

  static void addPoll(BuildContext context) {
    EditorRouter.open(context, isPoll: true);
  }

  static void addZapGoal(BuildContext context) {
    EditorRouter.open(context, isZapGoal: true);
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
    var s = S.of(context);

    List<Widget> entries = [];
    var index = 0;

    entries.add(AddBtnStartItemButton(
      iconData: Icons.note,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: s.Note,
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        AddBtnWrapperComponent.addNote(context);
      },
    ));
    entries.add(AddBtnStartItemButton(
      iconData: Icons.article,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: s.Article,
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        AddBtnWrapperComponent.addArticle(context);
      },
    ));
    entries.add(AddBtnStartItemButton(
      iconData: Icons.image,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: s.Media,
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        AddBtnWrapperComponent.addMedia(context);
      },
    ));
    entries.add(AddBtnStartItemButton(
      iconData: Icons.poll,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: s.Poll,
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        AddBtnWrapperComponent.addPoll(context);
      },
    ));
    entries.add(AddBtnStartItemButton(
      iconData: Icons.trending_up,
      iconBackgroundColor: ColorList.ALL_COLOR[++index],
      iconSize: iconSize,
      name: s.Zap_Goal,
      backgroundColor: cardColor,
      onTap: () {
        closeMenu();
        AddBtnWrapperComponent.addZapGoal(context);
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
