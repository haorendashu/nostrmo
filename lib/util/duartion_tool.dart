extension DurationTool on Duration {
  String prettyDuration() {
    var components = <String>[];

    var hours = inHours % 24;
    if (hours != 0) {
      if (hours > 9) {
        components.add('${hours}:');
      } else {
        components.add('0${hours}:');
      }
    }
    var minutes = inMinutes % 60;
    if (minutes > 9) {
      components.add('${minutes}:');
    } else {
      components.add('0${minutes}:');
    }

    var seconds = inSeconds % 60;
    if (seconds > 9) {
      components.add('${seconds}');
    } else {
      components.add('0${seconds}');
    }
    return components.join();
  }

  // String prettyDuration() {
  //   var components = <String>[];

  //   var days = inDays;
  //   if (days != 0) {
  //     components.add('${days}d');
  //   }
  //   var hours = inHours % 24;
  //   if (hours != 0) {
  //     components.add('${hours}h');
  //   }
  //   var minutes = inMinutes % 60;
  //   if (minutes != 0) {
  //     components.add('${minutes}m');
  //   }

  //   var seconds = inSeconds % 60;
  //   if (seconds != 0) {
  //     components.add('${seconds}s');
  //   }
  //   // var centiseconds = (inMilliseconds % 1000) ~/ 10;
  //   // if (components.isEmpty || seconds != 0 || centiseconds != 0) {
  //   //   components.add('$seconds');
  //   //   if (centiseconds != 0) {
  //   //     components.add('.');
  //   //     components.add(centiseconds.toString().padLeft(2, '0'));
  //   //   }
  //   //   components.add('s');
  //   // }
  //   return components.join();
  // }
}
