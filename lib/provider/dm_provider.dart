import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip04/dm_session.dart';
import 'package:nostr_sdk/nostr.dart';
import 'package:nostr_sdk/utils/peddingevents_later_function.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/base_consts.dart';

import '../data/dm_session_info.dart';
import '../data/dm_session_info_db.dart';
import '../data/event_db.dart';
import '../main.dart';

class DMProvider extends ChangeNotifier with PenddingEventsLaterFunction {
  static DMProvider? _dmProvider;

  List<DMSessionDetail> _knownList = [];

  List<DMSessionDetail> _unknownList = [];

  Map<String, DMSessionDetail> _sessionDetails = {};

  String? localPubkey;

  List<DMSessionDetail> get knownList => _knownList;

  List<DMSessionDetail> get unknownList => _unknownList;

  DMSessionDetail? getSessionDetail(String pubkey) {
    return _sessionDetails[pubkey];
  }

  DMSessionDetail findOrNewADetail(String pubkey) {
    for (var detail in knownList) {
      if (detail.dmSession.pubkey == pubkey) {
        return detail;
      }
    }

    for (var detail in _unknownList) {
      if (detail.dmSession.pubkey == pubkey) {
        return detail;
      }
    }

    var dmSession = DMSession(pubkey: pubkey);
    DMSessionDetail detail = DMSessionDetail(dmSession);
    detail.info = DMSessionInfo(pubkey: pubkey, readedTime: 0);

    return detail;
  }

  void updateReadedTime(DMSessionDetail? detail) {
    if (detail != null &&
        detail.info != null &&
        detail.dmSession.newestEvent != null) {
      detail.info!.readedTime = detail.dmSession.newestEvent!.createdAt;
      DMSessionInfoDB.update(detail.info!);
      notifyListeners();
    }
  }

  void addEventAndUpdateReadedTime(DMSessionDetail detail, Event event) {
    penddingEvents.add(event);
    eventLaterHandle(penddingEvents, updateUI: false);
    updateReadedTime(detail);
  }

  Future<DMSessionDetail> addDmSessionToKnown(DMSessionDetail detail) async {
    var keyIndex = settingProvider.privateKeyIndex!;
    var pubkey = detail.dmSession.pubkey;
    DMSessionInfo o = DMSessionInfo(pubkey: pubkey);
    o.keyIndex = keyIndex;
    o.readedTime = detail.dmSession.newestEvent!.createdAt;
    await DMSessionInfoDB.insert(o);

    detail.info = o;

    unknownList.remove(detail);
    knownList.add(detail);

    _sortDetailList();
    notifyListeners();

    return detail;
  }

  int _initSince = 0;

  Future<void> initDMSessions(String localPubkey) async {
    _sessionDetails.clear();
    _knownList.clear();
    _unknownList.clear();

    this.localPubkey = localPubkey;
    var keyIndex = settingProvider.privateKeyIndex!;
    var events = await EventDB.list(
        keyIndex,
        [
          EventKind.DIRECT_MESSAGE,
          EventKind.PRIVATE_DIRECT_MESSAGE,
          EventKind.PRIVATE_FILE_MESSAGE
        ],
        0,
        10000000);

    Map<String, List<Event>> eventListMap = {};
    for (var event in events) {
      // print("dmEvent");
      // print(event.toJson());
      var pubkey = _getPubkey(localPubkey, event);
      if (StringUtil.isNotBlank(pubkey)) {
        var list = eventListMap[pubkey!];
        if (list == null) {
          list = [];
          eventListMap[pubkey] = list;
        }
        list.add(event);

        if (event.kind == EventKind.DIRECT_MESSAGE &&
            event.createdAt > _initSince) {
          _initSince = event.createdAt;
        }
      }
    }

    Map<String, DMSessionInfo> infoMap = {};
    var infos = await DMSessionInfoDB.all(keyIndex);
    for (var info in infos) {
      infoMap[info.pubkey!] = info;
    }

    for (var entry in eventListMap.entries) {
      var pubkey = entry.key;
      var list = entry.value;

      var session = DMSession(pubkey: pubkey);
      session.addEvents(list);

      var info = infoMap[pubkey];
      var detail = DMSessionDetail(session, info: info);
      if (info != null) {
        _knownList.add(detail);
      } else {
        _unknownList.add(detail);
      }
      _sessionDetails[pubkey] = detail;
    }

    _sortDetailList();
    notifyListeners();
  }

  void _sortDetailList() {
    _doSortDetailList(_knownList);
    _doSortDetailList(_unknownList);
  }

  void _doSortDetailList(List<DMSessionDetail> detailList) {
    detailList.sort((detail0, detail1) {
      return detail1.dmSession.newestEvent!.createdAt -
          detail0.dmSession.newestEvent!.createdAt;
    });

    // // copy to a new list for provider update
    // var length = detailList.length;
    // List<DMSessionDetail> newlist =
    //     List.generate(length, (index) => detailList[index]);
    // return newlist;
  }

  String? _getPubkey(String localPubkey, Event event) {
    if (event.pubkey != localPubkey) {
      return event.pubkey;
    }

    for (var tag in event.tags) {
      if (tag[0] == "p") {
        return tag[1] as String;
      }
    }

    return null;
  }

  bool _addEvent(String localPubkey, Event event) {
    var pubkey = _getPubkey(localPubkey, event);
    if (StringUtil.isBlank(pubkey)) {
      return false;
    }

    var sessionDetail = _sessionDetails[pubkey];
    if (sessionDetail == null) {
      var session = DMSession(pubkey: pubkey!);
      sessionDetail = DMSessionDetail(session);
      _sessionDetails[pubkey] = sessionDetail;

      _unknownList.add(sessionDetail);
    }

    var addResult = sessionDetail.dmSession.addEvent(event);
    if (addResult) {
      _sortDetailList();
      // TODO
    }

    return addResult;
  }

  void query(
      {Nostr? targetNostr, bool initQuery = false, bool queryAll = false}) {
    targetNostr ??= nostr;
    var filter0 = Filter(
      kinds: [EventKind.DIRECT_MESSAGE],
      authors: [targetNostr!.publicKey],
    );
    var filter1 = Filter(
      kinds: [EventKind.DIRECT_MESSAGE],
      p: [targetNostr.publicKey],
    );

    if (!queryAll || _initSince == 0) {
      filter0.since = _initSince + 1;
      filter1.since = _initSince + 1;
    }

    if (initQuery) {
      targetNostr.addInitQuery([filter0.toJson(), filter1.toJson()], onEvent);
    } else {
      // targetNostr.pool.subscribe([filter0.toJson(), filter1.toJson()], onEvent);
      // print(filter0.toJson());
      // print(filter1.toJson());
      targetNostr.query([filter0.toJson(), filter1.toJson()], onEvent);
    }
  }

  // void handleEventImmediately(Event event) {
  //   penddingEvents.add(event);
  //   eventLaterHandle(penddingEvents);
  // }

  void onEvent(Event event) {
    later(event, eventLaterHandle, null);
  }

  void eventLaterHandle(List<Event> events, {bool updateUI = true}) {
    bool updated = false;
    List<Event> newEvents = [];

    for (var event in events) {
      var addResult = _addEvent(localPubkey!, event);
      // save to local
      if (addResult) {
        if (event.pubkey != nostr!.publicKey) {
          newEvents.add(event);
        }

        if (event.kind == EventKind.DIRECT_MESSAGE &&
            event.createdAt > _initSince) {
          _initSince = event.createdAt;
        }

        updated = true;
        var keyIndex = settingProvider.privateKeyIndex!;
        EventDB.insert(keyIndex, event);
      }
    }

    if (updated) {
      _sortDetailList();
      if (updateUI) {
        notifyListeners();
      }

      if (PlatformUtil.isPC() &&
          settingProvider.messageNotice != OpenStatus.CLOSE) {
        var newEventsLength = newEvents.length;
        if (newEventsLength > 1) {
          localNotificationBuilder.sendDMsNumberNotification(newEventsLength);
        } else if (newEventsLength == 1) {
          localNotificationBuilder.sendNotification(newEvents.first);
        }
      }
    }
  }

  void clear() {
    _sessionDetails.clear();
    _knownList.clear();
    _unknownList.clear();

    notifyListeners();
  }
}

class DMSessionDetail {
  DMSession dmSession;
  DMSessionInfo? info;

  DMSessionDetail(this.dmSession, {this.info});

  bool hasNewMessage() {
    if (info == null) {
      return true;
    } else if (dmSession.newestEvent != null &&
        info!.readedTime! < dmSession.newestEvent!.createdAt) {
      return true;
    }
    return false;
  }
}
