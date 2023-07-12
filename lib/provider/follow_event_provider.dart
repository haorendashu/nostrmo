import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';

import '../../client/event_kind.dart' as kind;
import '../client/event.dart';
import '../client/nip02/contact.dart';
import '../client/nip02/cust_contact_list.dart';
import '../client/filter.dart';
import '../client/nostr.dart';
import '../data/event_mem_box.dart';
import '../main.dart';
import '../router/tag/topic_map.dart';
import '../util/find_event_interface.dart';
import '../util/peddingevents_later_function.dart';
import '../util/string_util.dart';

class FollowEventProvider extends ChangeNotifier
    with PenddingEventsLaterFunction
    implements FindEventInterface {
  late int _initTime;

  late EventMemBox eventBox;

  late EventMemBox postsBox;

  FollowEventProvider() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox = EventMemBox(sortAfterAdd: false); // sortAfterAdd by call
    postsBox = EventMemBox(sortAfterAdd: false);
  }

  @override
  List<Event> findEvent(String str, {int? limit = 5}) {
    return eventBox.findEvent(str, limit: limit);
  }

  List<Event> eventsByPubkey(String pubkey) {
    return eventBox.listByPubkey(pubkey);
  }

  void refresh() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    eventBox.clear();
    postsBox.clear();
    doQuery();

    followNewEventProvider.clear();
  }

  int lastTime() {
    return _initTime;
  }

  List<String> _subscribeIds = [];

  void deleteEvent(String id) {
    postsBox.delete(id);
    var result = eventBox.delete(id);
    if (result) {
      notifyListeners();
    }
  }

  List<int> queryEventKinds() {
    return [
      kind.EventKind.TEXT_NOTE,
      kind.EventKind.REPOST,
      kind.EventKind.GENERIC_REPOST,
      kind.EventKind.LONG_FORM,
      kind.EventKind.FILE_HEADER,
      kind.EventKind.POLL,
    ];
  }

  void doQuery(
      {Nostr? targetNostr,
      bool initQuery = false,
      int? until,
      bool forceUserLimit = false}) {
    var filter = Filter(
      kinds: queryEventKinds(),
      until: until ?? _initTime,
      limit: 20,
    );
    targetNostr ??= nostr!;
    bool queriedTags = false;

    doUnscribe(targetNostr);

    List<String> subscribeIds = [];
    Iterable<Contact> contactList = contactListProvider.list();
    var contactListLength = contactList.length;
    List<String> ids = [];
    // timeline pull my events too.
    int maxQueryIdsNum = 400;
    if (contactListLength > maxQueryIdsNum) {
      var times = (contactListLength / maxQueryIdsNum).ceil();
      maxQueryIdsNum = (contactListLength / times).ceil();
    }
    maxQueryIdsNum += 2;
    ids.add(targetNostr.publicKey);
    for (Contact contact in contactList) {
      ids.add(contact.publicKey);
      if (ids.length > maxQueryIdsNum) {
        filter.authors = ids;
        var subscribeId = _doQueryFunc(targetNostr, filter,
            initQuery: initQuery,
            forceUserLimit: forceUserLimit,
            queriyTags: !queriedTags);
        subscribeIds.add(subscribeId);
        ids = [];
        queriedTags = true;
      }
    }
    if (ids.isNotEmpty) {
      filter.authors = ids;
      var subscribeId = _doQueryFunc(targetNostr, filter,
          initQuery: initQuery,
          forceUserLimit: forceUserLimit,
          queriyTags: !queriedTags);
      subscribeIds.add(subscribeId);
    }

    if (!initQuery) {
      _subscribeIds = subscribeIds;
    }
  }

  void doUnscribe(Nostr targetNostr) {
    if (_subscribeIds.isNotEmpty) {
      for (var subscribeId in _subscribeIds) {
        try {
          targetNostr.unsubscribe(subscribeId);
        } catch (e) {}
      }
      _subscribeIds.clear();
    }
  }

  String _doQueryFunc(Nostr targetNostr, Filter filter,
      {bool initQuery = false,
      bool forceUserLimit = false,
      bool queriyTags = false}) {
    var subscribeId = StringUtil.rndNameStr(12);
    if (initQuery) {
      // tags query can't query by size! if will make timeline xxxx
      // targetNostr.addInitQuery(
      //     addTagFilter([filter.toJson()], queriyTags), onEvent,
      //     id: subscribeId);
      targetNostr.addInitQuery([filter.toJson()], onEvent, id: subscribeId);
    } else {
      if (!eventBox.isEmpty()) {
        var activeRelays = targetNostr.activeRelays();
        var oldestCreatedAts =
            eventBox.oldestCreatedAtByRelay(activeRelays, _initTime);
        Map<String, List<Map<String, dynamic>>> filtersMap = {};
        for (var relay in activeRelays) {
          var oldestCreatedAt = oldestCreatedAts.createdAtMap[relay.url];
          if (oldestCreatedAt != null) {
            filter.until = oldestCreatedAt;
            if (!forceUserLimit) {
              filter.limit = null;
              if (filter.until! < oldestCreatedAts.avCreatedAt - 60 * 60 * 18) {
                filter.since = oldestCreatedAt - 60 * 60 * 12;
              } else if (filter.until! >
                  oldestCreatedAts.avCreatedAt - 60 * 60 * 6) {
                filter.since = oldestCreatedAt - 60 * 60 * 36;
              } else {
                filter.since = oldestCreatedAt - 60 * 60 * 24;
              }
            }
            filtersMap[relay.url] =
                addTagCommunityFilter([filter.toJson()], queriyTags);
          }
        }
        targetNostr.queryByFilters(filtersMap, onEvent, id: subscribeId);
      } else {
        // this maybe refresh
        targetNostr.query(
            addTagCommunityFilter([filter.toJson()], queriyTags), onEvent,
            id: subscribeId);
      }
    }
    return subscribeId;
  }

  static List<Map<String, dynamic>> addTagCommunityFilter(
      List<Map<String, dynamic>> filters, bool queriyTags) {
    if (queriyTags && filters.isNotEmpty) {
      var filter = filters[0];
      // tags filter
      {
        var tagFilter = Map<String, dynamic>.from(filter);
        tagFilter.remove("authors");
        // handle tag with TopicMap
        var tagList = contactListProvider.tagList().toList();
        List<String> queryTagList = [];
        for (var tag in tagList) {
          var list = TopicMap.getList(tag);
          if (list != null) {
            queryTagList.addAll(list);
          } else {
            queryTagList.add(tag);
          }
        }
        tagFilter["#t"] = queryTagList;
        filters.add(tagFilter);
      }
      // community filter
      {
        var communityFilter = Map<String, dynamic>.from(filter);
        communityFilter.remove("authors");
        var communityList =
            contactListProvider.followedCommunitiesList().toList();
        communityFilter["#a"] = communityList;
        filters.add(communityFilter);
      }
    }
    return filters;
  }

  // check if is posts (no tag e and not Mentions, TODO handle NIP27)
  static bool eventIsPost(Event event) {
    bool isPosts = true;
    var tagLength = event.tags.length;
    for (var i = 0; i < tagLength; i++) {
      var tag = event.tags[i];
      if (tag.length > 0 && tag[0] == "e") {
        if (event.content.contains("[$i]")) {
          continue;
        }

        isPosts = false;
        break;
      }
    }

    return isPosts;
  }

  void mergeNewEvent() {
    var allEvents = followNewEventProvider.eventMemBox.all();
    var postEvnets = followNewEventProvider.eventPostMemBox.all();

    eventBox.addList(allEvents);
    postsBox.addList(postEvnets);

    // sort
    eventBox.sort();
    postsBox.sort();

    followNewEventProvider.clear();

    // update ui
    notifyListeners();
  }

  void onEvent(Event event) {
    if (eventBox.isEmpty()) {
      laterTimeMS = 200;
    } else {
      laterTimeMS = 500;
    }
    later(event, (list) {
      bool added = false;
      for (var e in list) {
        var result = eventBox.add(e);
        if (result) {
          // add success
          added = true;

          // check if is posts (no tag e)
          bool isPosts = eventIsPost(e);
          if (isPosts) {
            postsBox.add(e);
          }
        }
      }

      if (added) {
        // sort
        eventBox.sort();
        postsBox.sort();

        // update ui
        notifyListeners();
      }
    }, null);
  }

  void clear() {
    eventBox.clear();
    postsBox.clear();

    doUnscribe(nostr!);

    notifyListeners();
  }

  void metadataUpdatedCallback(CustContactList? _contactList) {
    if (firstLogin ||
        (eventBox.isEmpty() &&
            _contactList != null &&
            !_contactList.isEmpty())) {
      doQuery();
    }

    if (firstLogin && _contactList != null && _contactList.list().length > 10) {
      firstLogin = false;
    }
  }
}
