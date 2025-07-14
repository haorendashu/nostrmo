import 'package:flutter/material.dart';

import '../../generated/l10n.dart';

class ZapInfoInputComponent extends StatelessWidget {
  TextEditingController numController;

  TextEditingController commentController;

  ZapInfoInputComponent(this.numController, this.commentController);

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var numberSize = 30.0;
    var s = S.of(context);

    List<Widget> inputList = [];
    inputList.add(Container(
      child: TextField(
        autofocus: true,
        controller: numController,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "0",
          hintStyle: TextStyle(
            fontSize: numberSize,
            fontWeight: FontWeight.bold,
            color: themeData.hintColor,
          ),
        ),
        style: TextStyle(
          fontSize: numberSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
    inputList.add(Container(
      child: const Text("sats"),
    ));
    inputList.add(Container(
      margin: EdgeInsets.only(top: 26),
      child: Text(s.Comment),
    ));
    inputList.add(Container(
      child: TextField(
        controller: commentController,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "( ${s.Optional} )",
          hintStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeData.hintColor,
          ),
        ),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: inputList,
    );
  }
}
