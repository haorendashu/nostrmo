import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/cust_nostr.dart';

import '../data/relay_status.dart';
import 'cust_relay.dart';

CustNostr genNostr(String pk) {
  var _nostr = CustNostr(privateKey: pk);
  // TODO add subscript
  // load relay addr and init
  _loadRelayAndInit(_nostr);
  return _nostr;
}

void _loadRelayAndInit(CustNostr _nostr) {
  List<String> relayAddrs = ["wss://nos.lol"];
  // TODO load relay addr

  for (var relayAddr in relayAddrs) {
    var relayStatus = RelayStatus(relayAddr);
    var relay = Relay(
      relayStatus.addr,
      access: WriteAccess.readWrite,
    );
    var custRelay = CustRelay(relay, relayStatus);

    _nostr.pool.add(custRelay, autoSubscribe: true);
  }
}
