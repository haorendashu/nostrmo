import 'dart:async';
import 'dart:developer';

import 'package:nostrmo/main.dart';

class SystemTimer {
  static int counter = 0;

  static Timer? timer;

  static void run() {
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(Duration(seconds: 30), (timer) {
      try {
        runTask();
        counter++;
      } catch (e) {
        print(e);
      }
    });
  }

  static void runTask() {
    // log("SystemTimer runTask");
    if (counter % 2 == 0 && nostr != null) {
      relayProvider.checkAndReconnect();
      mentionMeNewProvider.queryNew();
    } else {
      followNewEventProvider.queryNew();
    }
  }

  static void stopTask() {
    if (timer != null) {
      timer!.cancel();
    }
  }
}
