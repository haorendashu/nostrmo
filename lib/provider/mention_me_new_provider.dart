import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/provider/local_notification_builder.dart';

import '../consts/base_consts.dart';
import '../main.dart';

class MentionMeNewProvider extends ChangeNotifier
    with PenddingEventsLaterFunction {
  EventMemBox eventMemBox = EventMemBox();

  int? _localSince;

  String? subscribeId;

  void queryNew() {
    if (subscribeId != null) {
      try {
        nostr!.unsubscribe(subscribeId!);
      } catch (e) {}
    }

    _localSince =
        _localSince == null || mentionMeProvider.lastTime() > _localSince!
            ? mentionMeProvider.lastTime()
            : _localSince;

    subscribeId = StringUtil.rndNameStr(12);
    var filter = Filter(
      since: _localSince! + 1,
      kinds: mentionMeProvider.queryEventKinds(),
      p: [nostr!.publicKey],
    );
    nostr!.query([filter.toJson()], (event) {
      later(event, handleEvents, null);
    }, id: subscribeId);
  }

  handleEvents(List<Event> events) {
    bool hasNew = false;
    bool shouldNotice = false;
    if (PlatformUtil.isPC() &&
        settingProvider.followNoteNotice != OpenStatus.CLOSE) {
      shouldNotice = true;
    }

    for (var event in events) {
      if (eventMemBox.add(event)) {
        hasNew = true;

        if (shouldNotice) {
          localNotificationBuilder.sendNotification(event);
        }
      }
    }

    if (hasNew) {
      _localSince = eventMemBox.newestEvent!.createdAt;
      notifyListeners();
    }
  }

  void clear() {
    eventMemBox.clear();

    notifyListeners();
  }
}
