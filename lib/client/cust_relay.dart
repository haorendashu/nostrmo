import '../data/relay_status.dart';

import 'package:nostr_dart/nostr_dart.dart';

class CustRelay {
  Relay relay;
  RelayStatus relayStatus;

  CustRelay(this.relay, this.relayStatus);
}
