import 'package:flutter/material.dart';

import '../client/cust_relay.dart';
import '../main.dart';
import 'data_util.dart';

class RelayProvider extends ChangeNotifier {
  static RelayProvider? _relayProvider;

  List<String> relayUrls = [];

  List<CustRelay> relays = [];

  static RelayProvider getInstance() {
    if (_relayProvider == null) {
      _relayProvider = RelayProvider();
      _relayProvider!._load();
    }
    return _relayProvider!;
  }

  List<String>? _load() {
    relayUrls.clear();
    var list = sharedPreferences.getStringList(DataKey.RELAY_LIST);
    if (list != null) {
      relayUrls.addAll(relayUrls);
    }

    if (relayUrls.isEmpty) {
      // init relays
      relayUrls = [
        "wss://nos.lol",
        "wss://nostr.wine",
        "wss://atlas.nostr.land",
        "wss://relay.orangepill.dev",
        "wss://relay.damus.io",
      ];
    }
  }

  String relayNumStr() {
    var total = relayUrls.length;
    var relayNum = relays.length;
    return "$relayNum / $total";
  }

  // CustNostr genNostr(String pk) {
  //   var _nostr = CustNostr(privateKey: pk);
  //   log("nostr init over");

  //   _nostr.pool.listenRelayAdded(relayAddedListener);
  //   _nostr.pool.listenRelayRemoved(relayRemovedListener);

  //   for (var relayAddr in relayUrls) {
  //     var relayStatus = RelayStatus(relayAddr);
  //     var relay = Relay(
  //       relayStatus.addr,
  //       access: WriteAccess.readWrite,
  //     );
  //     var custRelay = CustRelay(relay, relayStatus);

  //     _nostr.pool.add(custRelay, autoSubscribe: true);
  //   }

  //   return _nostr;
  // }

  void relayAddedListener(CustRelay custRelay) {
    relays.add(custRelay);
    notifyListeners();
  }

  void relayRemovedListener(CustRelay custRelay) {
    relays.removeWhere((element) {
      return element.relay.url == custRelay.relay.url;
    });
    notifyListeners();
  }
}
