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
    timer = Timer.periodic(Duration(minutes: 1), (timer) {
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
    relayProvider.checkAndReconnect();
    if (counter % 2 == 0 && nostr != null) {
      followNewEventProvider.queryNew();
      mentionMeNewProvider.queryNew();
    }
  }

  static void stopTask() {
    if (timer != null) {
      timer!.cancel();
    }
  }
}
