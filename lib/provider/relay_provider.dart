import 'dart:developer';

import 'package:flutter/material.dart';

import '../client/event.dart';
import '../client/event_kind.dart' as kind;
import '../client/nostr.dart';
import '../client/relay.dart';
import '../consts/client_connected.dart';
import '../data/relay_status.dart';
import '../main.dart';
import 'data_util.dart';

class RelayProvider extends ChangeNotifier {
  static RelayProvider? _relayProvider;

  List<String> relayAddrs = [];

  Map<String, RelayStatus> relayStatusMap = {};

  static RelayProvider getInstance() {
    if (_relayProvider == null) {
      _relayProvider = RelayProvider();
      _relayProvider!._load();
    }
    return _relayProvider!;
  }

  List<String>? _load() {
    relayAddrs.clear();
    var list = sharedPreferences.getStringList(DataKey.RELAY_LIST);
    if (list != null) {
      relayAddrs.addAll(list);
    }

    if (relayAddrs.isEmpty) {
      // init relays
      relayAddrs = [
        "wss://nos.lol",
        "wss://nostr.wine",
        "wss://atlas.nostr.land",
        "wss://relay.orangepill.dev",
        "wss://relay.damus.io",
        // "wss://relay.nostr.bg/",
        // "wss://universe.nostrich.land/",
        // "wss://relay.snort.social/",
        // "wss://universe.nostrich.land",
        // "wss://filter.nostr.wine",
        // "wss://nostr.vpn1.codingmerc.com",
      ];
    }
  }

  RelayStatus? getRelayStatus(String addr) {
    return relayStatusMap[addr];
  }

  String relayNumStr() {
    var total = relayAddrs.length;

    int connectedNum = 0;
    var it = relayStatusMap.values;
    for (var status in it) {
      if (status.connected == ClientConneccted.CONNECTED) {
        connectedNum++;
      }
    }
    return "$connectedNum / $total";
  }

  int total() {
    return relayAddrs.length;
  }

  Nostr genNostr(String pk) {
    var _nostr = Nostr(privateKey: pk);
    log("nostr init over");

    // add initQuery
    var dmInitFuture = dmProvider.initDMSessions(_nostr.publicKey);
    contactListProvider.reload(targetNostr: _nostr);
    contactListProvider.query(targetNostr: _nostr);
    followEventProvider.doQuery(targetNostr: _nostr, initQuery: true);
    mentionMeProvider.doQuery(targetNostr: _nostr, initQuery: true);
    dmInitFuture.then((_) {
      dmProvider.query(targetNostr: _nostr, initQuery: true);
    });

    for (var relayAddr in relayAddrs) {
      log("begin to init $relayAddr");
      var custRelay = genRelay(relayAddr);
      try {
        _nostr.addRelay(custRelay, init: true);
      } catch (e) {
        log("relay $relayAddr add to pool error ${e.toString()}");
      }
    }

    return _nostr;
  }

  void onRelayStatusChange() {
    notifyListeners();
  }

  void addRelay(String relayAddr) {
    if (!relayAddrs.contains(relayAddr)) {
      relayAddrs.add(relayAddr);
      _doAddRelay(relayAddr);
      _updateRelayToData();
    }
  }

  void _doAddRelay(String relayAddr, {bool init = false}) {
    var custRelay = genRelay(relayAddr);
    log("begin to init $relayAddr");
    nostr!.addRelay(custRelay, autoSubscribe: true, init: init);
  }

  void removeRelay(String relayAddr) {
    if (relayAddrs.contains(relayAddr)) {
      relayAddrs.remove(relayAddr);
      nostr!.removeRelay(relayAddr);

      _updateRelayToData();
    }
  }

  bool containRelay(String relayAddr) {
    return relayAddrs.contains(relayAddr);
  }

  int? updatedTime() {
    return sharedPreferences.getInt(DataKey.RELAY_UPDATED_TIME);
  }

  void _updateRelayToData({bool upload = true}) {
    sharedPreferences.setStringList(DataKey.RELAY_LIST, relayAddrs);
    sharedPreferences.setInt(DataKey.RELAY_UPDATED_TIME,
        DateTime.now().millisecondsSinceEpoch ~/ 1000);

    // update to relay
    if (upload) {
      List<dynamic> tags = [];
      for (var addr in relayAddrs) {
        tags.add(["r", addr, ""]);
      }
      var event =
          Event(nostr!.publicKey, kind.EventKind.RELAY_LIST_METADATA, tags, "");
      nostr!.sendEvent(event);
    }
  }

  Relay genRelay(String relayAddr) {
    var relayStatus = relayStatusMap[relayAddr];
    if (relayStatus == null) {
      relayStatus = RelayStatus(relayAddr);
      relayStatusMap[relayAddr] = relayStatus;
    }

    return Relay(
      relayAddr,
      relayStatus,
      access: WriteAccess.readWrite,
    )..relayStatusCallback = onRelayStatusChange;
  }

  void setRelayListAndUpdate(List<String> addrs) {
    relayStatusMap.clear();

    relayAddrs.clear();
    relayAddrs.addAll(addrs);
    _updateRelayToData(upload: false);

    nostr!.close();
    nostr = Nostr(privateKey: nostr!.privateKey);

    // reconnect all client
    for (var relayAddr in relayAddrs) {
      var custRelay = genRelay(relayAddr);
      try {
        nostr!.addRelay(custRelay, autoSubscribe: true);
      } catch (e) {
        log("relay $relayAddr add to pool error ${e.toString()}");
      }
    }
  }

  void clear() {
    // sharedPreferences.remove(DataKey.RELAY_LIST);
    relayStatusMap.clear();
    _load();
  }
}
