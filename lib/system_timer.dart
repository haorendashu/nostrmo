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
    timer = Timer.periodic(Duration(seconds: 15), (timer) {
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
    if (nostr != null) {
      if (counter % 2 == 0) {
        // relayProvider.checkAndReconnect();
        if (counter > 4) {
          mentionMeNewProvider.queryNew();
          dmProvider.query();
        }
      } else {
        if (counter > 4) {
          followNewEventProvider.queryNew();
          giftWrapProvider.query();
        }
      }
    }

    if (counter % 10 == 0) {
      try {
        relayProvider.cleanTempRelays();
      } catch (e) {
        print(e);
      }
    }
  }

  static void stopTask() {
    if (timer != null) {
      timer!.cancel();
    }
  }
}
