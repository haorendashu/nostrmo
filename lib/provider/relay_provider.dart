import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';

import '../client/event_kind.dart' as kind;
import '../client/cust_nostr.dart';
import '../client/cust_relay.dart';
import '../client/real_relay.dart';
import '../data/relay_status.dart';
import '../main.dart';
import 'data_util.dart';

class RelayProvider extends ChangeNotifier {
  static RelayProvider? _relayProvider;

  List<String> relayAddrs = [];

  List<CustRelay> relays = [];

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
        // "wss://universe.nostrich.land",
        // "wss://filter.nostr.wine"
        // "wss://nostr.vpn1.codingmerc.com",
      ];
    }
  }

  RelayStatus? getRelayStatus(String addr) {
    return relayStatusMap[addr];
  }

  void checkAndReconnect() {
    Map<String, CustRelay> relayMap = {};
    for (var custRelay in relays) {
      relayMap[custRelay.relayStatus.addr] = custRelay;
    }

    var relayIsEmpty = relayMap.isEmpty;

    for (var addr in relayAddrs) {
      var custRelay = relayMap[addr];
      if (custRelay == null) {
        _doAddRelay(addr, init: relayIsEmpty);
      }
    }
  }

  String relayNumStr() {
    var total = relayAddrs.length;
    var relayNum = relays.length;
    return "$relayNum / $total";
  }

  int total() {
    return relayAddrs.length;
  }

  CustNostr genNostr(String pk) {
    var _nostr = CustNostr(privateKey: pk);
    log("nostr init over");

    _nostr.pool.listenRelayAdded(relayAddedListener);
    _nostr.pool.listenRelayRemoved(relayRemovedListener);

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
        _nostr.pool.add(custRelay, init: true);
      } catch (e) {
        log("relay $relayAddr add to pool error ${e.toString()}");
      }
    }

    return _nostr;
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
    nostr!.pool.add(custRelay, autoSubscribe: true, init: init);
  }

  void removeRelay(String relayAddr) {
    if (relayAddrs.contains(relayAddr)) {
      relayAddrs.remove(relayAddr);
      nostr!.pool.remove(relayAddr);

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

  CustRelay genRelay(String relayAddr) {
    var relayStatus = relayStatusMap[relayAddr];
    if (relayStatus == null) {
      relayStatus = RelayStatus(relayAddr);
      relayStatusMap[relayAddr] = relayStatus;
    }

    var relay = RealRelay(
      relayStatus.addr,
      access: WriteAccess.readWrite,
    );
    return CustRelay(relay, relayStatus);
  }

  void relayAddedListener(CustRelay custRelay) {
    relays.add(custRelay);
    custRelay.relayStatus.connected = true;
    notifyListeners();
  }

  void relayRemovedListener(CustRelay custRelay) {
    custRelay.relayStatus.connected = false;
    relays.removeWhere((element) {
      return element.relay.url == custRelay.relay.url;
    });
    notifyListeners();
  }

  void setRelayListAndUpdate(List<String> addrs) {
    relayStatusMap.clear();
    relays.clear();

    relayAddrs.clear();
    relayAddrs.addAll(addrs);
    _updateRelayToData(upload: false);

    nostr!.close;
    checkAndReconnect();
  }

  void clear() {
    // sharedPreferences.remove(DataKey.RELAY_LIST);
    relayStatusMap.clear();
    relays.clear();
    _load();
  }
}
