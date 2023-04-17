import 'package:flutter/material.dart';
import 'package:nostrmo/consts/base.dart';

import '../generated/l10n.dart';

class NewNotesUpdatedComponent extends StatelessWidget {
  int num;

  Function? onTap;

  NewNotesUpdatedComponent({required this.num, this.onTap});

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var textColor = themeData.appBarTheme.titleTextStyle!.color;

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
        ),
        decoration: BoxDecoration(
          color: mainColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "$num ${S.of(context).notes_updated}",
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }
}
