import 'package:flutter/material.dart';

class SimpleDateComponent extends StatelessWidget {
  int date;

  SimpleDateComponent(this.date);

  int minuteTime = 60;

  int hourTime = 60 * 60;

  int dayTime = 60 * 60 * 24;

  int monthTime = 60 * 60 * 24 * 31;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    String text = "";
    var t = now - date;
    if (t < minuteTime) {
      if (t < 0) {
        t = 0;
      }
      text = "${t}s";
    } else if (t < hourTime) {
      t = t ~/ minuteTime;
      text = "${t}m";
    } else if (t < dayTime) {
      t = t ~/ hourTime;
      text = "${t}h";
    } else if (t < monthTime) {
      t = t ~/ dayTime;
      text = "${t}d";
    } else {
      var dt = DateTime.fromMillisecondsSinceEpoch(date * 1000);
      text = "${dt.year}-${dt.month}-${dt.day}";
    }

    return Container(
      child: Text(
        text,
        style: TextStyle(
          color: themeData.hintColor,
          fontSize: themeData.textTheme.bodySmall!.fontSize,
        ),
      ),
    );
  }
}
