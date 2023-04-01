import 'dart:async';
import 'dart:developer';

import 'package:nostrmo/main.dart';

class SystemTimer {
  static Timer? timer;

  static void run() {
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(Duration(minutes: 1), (timer) {
      try {
        runTask();
      } catch (e) {
        print(e);
      }
    });
  }

  static void runTask() {
    // log("SystemTimer runTask");
    relayProvider.checkAndReconnect();
  }

  static void stopTask() {
    if (timer != null) {
      timer!.cancel();
    }
  }
}
