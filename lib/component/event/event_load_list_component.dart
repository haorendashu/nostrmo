import 'package:flutter/material.dart';

import '../../consts/base.dart';
import '../../generated/l10n.dart';

class EventLoadListComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;

    var s = S.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
      color: cardColor,
      height: 60,
      child: Center(child: Text(s.Note_loading)),
    );
  }
}
