import '../data/relay_status.dart';

import 'package:nostr_dart/nostr_dart.dart';

import 'subscription.dart';

class CustRelay {
  Relay relay;
  RelayStatus relayStatus;

  final Map<String, Subscription> _queries = {};

  CustRelay(this.relay, this.relayStatus);

  void saveQuery(Subscription subscription) {
    _queries[subscription.id] = subscription;
  }

  bool checkQuery(String id) {
    return _queries[id] != null;
  }

  bool checkAndCompleteQuery(String id) {
    // all subscription should be close
    send(["CLOSE", id]);
    var sub = _queries.remove(id);
    if (sub != null) {
      return true;
    }
    return false;
  }

  Subscription? getRequestSubscription(String id) {
    return _queries[id];
  }

  Future<void> send(List<dynamic> message) {
    return relay.send(message);
  }

  void listen(Function(CustRelay, List<dynamic>) callback) {
    relay.listen((List<dynamic> json) {
      callback(this, json);
    });
  }
}
