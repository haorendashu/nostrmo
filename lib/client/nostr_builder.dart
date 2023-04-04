// import 'dart:developer';

// import 'package:nostr_dart/nostr_dart.dart';
// import 'package:nostrmo/client/cust_nostr.dart';
// import 'package:nostrmo/main.dart';

// import '../data/relay_status.dart';
// import 'cust_relay.dart';

// @deprecated
// CustNostr genNostr(String pk) {
//   // init nostr
//   var _nostr = CustNostr(privateKey: pk);
//   log("nostr init over");

//   _nostr.pool.listenRelayAdded(relayProvider.relayAddedListener);
//   _nostr.pool.listenRelayRemoved(relayProvider.relayRemovedListener);

//   // add initQuery
//   var dmInitFuture = dmProvider.initDMSessions(_nostr.publicKey);
//   contactListProvider.query(targetNostr: _nostr);
//   followEventProvider.doQuery(targetNostr: _nostr, initQuery: true);
//   mentionMeProvider.doQuery(targetNostr: _nostr, initQuery: true);
//   dmInitFuture.then((_) {
//     dmProvider.subscribe(targetNostr: _nostr, initQuery: true);
//   });

//   // load relay addr and init
//   _loadRelayAndInit(_nostr);

//   return _nostr;
// }

// Future<void> _loadRelayAndInit(CustNostr _nostr) async {
//   // TODO change nostr init to relayProvider

//   List<String> relayAddrs = [
//     "wss://nos.lol",
//     "wss://nostr.wine",
//     "wss://atlas.nostr.land",
//     "wss://relay.orangepill.dev",
//     "wss://relay.damus.io",
//   ];
//   // TODO load relay addr

//   // List<Future> futureList = [];
//   for (var relayAddr in relayAddrs) {
//     var relayStatus = RelayStatus(relayAddr);
//     var relay = Relay(
//       relayStatus.addr,
//       access: WriteAccess.readWrite,
//     );
//     var custRelay = CustRelay(relay, relayStatus);

//     var future = _nostr.pool.add(custRelay, autoSubscribe: true);
//     // futureList.add(future);
//   }
//   // await Future.wait(futureList);
// }
