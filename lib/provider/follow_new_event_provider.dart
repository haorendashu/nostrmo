import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip02/contact.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/base_consts.dart';

import '../main.dart';
import 'follow_event_provider.dart';

class FollowNewEventProvider extends ChangeNotifier
    with PenddingEventsLaterFunction {
  EventMemBox eventPostMemBox = EventMemBox(sortAfterAdd: false);
  EventMemBox eventMemBox = EventMemBox(sortAfterAdd: false);

  int? _localSince;

  List<String> _subscribeIds = [];

  void doUnscribe() {
    if (_subscribeIds.isNotEmpty) {
      for (var subscribeId in _subscribeIds) {
        try {
          nostr!.unsubscribe(subscribeId);
        } catch (e) {}
      }
      _subscribeIds.clear();
    }
  }

  void queryNew() {
    doUnscribe();

    bool queriedTags = false;
    _localSince =
        _localSince == null || followEventProvider.lastTime() > _localSince!
            ? followEventProvider.lastTime()
            : _localSince;
    var filter = Filter(
        since: _localSince! + 1, kinds: followEventProvider.queryEventKinds());

    List<String> subscribeIds = [];
    Iterable<Contact> contactList = contactListProvider.list();
    List<String> ids = [];
    for (Contact contact in contactList) {
      ids.add(contact.publicKey);
      if (ids.length > 100) {
        filter.authors = ids;
        var subscribeId = _doQueryFunc(filter, queriyTags: queriedTags);
        subscribeIds.add(subscribeId);
        ids = [];
        queriedTags = true;
      }
    }
    if (ids.isNotEmpty) {
      filter.authors = ids;
      var subscribeId = _doQueryFunc(filter, queriyTags: queriedTags);
      subscribeIds.add(subscribeId);
    }

    _subscribeIds = subscribeIds;
  }

  String _doQueryFunc(Filter filter, {bool queriyTags = false}) {
    var subscribeId = StringUtil.rndNameStr(12);
    nostr!.query(
        FollowEventProvider.addTagCommunityFilter(
            [filter.toJson()], queriyTags), (event) {
      later(event, handleEvents, null);
    }, id: subscribeId);
    return subscribeId;
  }

  void clear() {
    eventPostMemBox.clear();
    eventMemBox.clear();

    notifyListeners();
  }

  handleEvents(List<Event> events) {
    bool hasNew = false;
    bool shouldNotice = false;
    if (PlatformUtil.isPC() &&
        settingProvider.followNoteNotice != OpenStatus.CLOSE) {
      shouldNotice = true;
    }
    for (var event in events) {
      if (followEventProvider.existEvent(event.id)) {
        continue;
      }

      var isNew = eventMemBox.add(event);
      if (isNew && shouldNotice) {
        hasNew = true;
        localNotificationBuilder.sendNotification(event);
      }
    }

    if (hasNew) {
      eventMemBox.sort();
    }
    _localSince = eventMemBox.newestEvent!.createdAt;

    for (var event in events) {
      bool isPosts = FollowEventProvider.eventIsPost(event);
      if (isPosts) {
        eventPostMemBox.add(event);
      }
    }

    notifyListeners();
  }
}
