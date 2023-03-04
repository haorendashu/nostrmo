import '../data/relay_status.dart';

import 'package:nostr_dart/nostr_dart.dart';

class CustRelay {
  Relay relay;
  RelayStatus relayStatus;

  CustRelay(this.relay, this.relayStatus);

  void listen(Function(CustRelay, List<dynamic>) callback) {
    relay.listen((List<dynamic> json) {
      callback(this, json);
    });
  }
}
