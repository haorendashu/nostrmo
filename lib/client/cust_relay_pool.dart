import 'dart:developer';

import 'package:nostr_dart/nostr_dart.dart';

import 'cust_relay.dart';
import 'subscription.dart';

class CustRelayPool {
  final Map<String, CustRelay> _relays = {};
  final Map<String, Subscription> _subscriptions = {};
  final bool _doSignatureVerification;

  CustRelayPool({bool disableSignatureVerification = false})
      : _doSignatureVerification = !disableSignatureVerification;

  List<String> get list => _relays.keys.toList();

  List<String> get subscriptions => _subscriptions.keys.toList();

  Map<String, RelayInfo> get info =>
      _relays.map((key, value) => MapEntry(key, value.relay.info));

  Map<String, bool> get isConnected =>
      _relays.map((key, value) => MapEntry(key, value.relay.isConnected));

  Future<bool> add(CustRelay custRelay, {bool autoSubscribe = false}) async {
    if (_relays.containsKey(custRelay.relay.url)) {
      return true;
    }

    custRelay.relay.onError = (url) {
      log('Could not send or reconnect to relay $url');
      remove(url);
    };

    // custRelay.relay.listen(_onEvent);
    custRelay.listen(_onEvent);

    if (await custRelay.relay.connect()) {
      log("connect complete!");
      _relays[custRelay.relay.url] = custRelay;
      if (autoSubscribe) {
        for (Subscription subscription in _subscriptions.values) {
          custRelay.relay.send(subscription.toJson());
        }
      }
      return true;
    }
    return false;
  }

  void remove(String url) {
    log('Removing $url');
    _relays[url]?.relay.disconnect();
    _relays.remove(url);
  }

  Future<void> send(List<dynamic> message) async {
    List<Future<void>> futures = [];

    // TODO filter relay by relayStatus
    for (CustRelay custRelay in _relays.values) {
      if (message[0] == "EVENT") {
        if (custRelay.relay.access == WriteAccess.readOnly) {
          continue;
        }
      }
      if (message[0] == "REQ" || message[0] == "CLOSE") {
        if (custRelay.relay.access == WriteAccess.writeOnly) {
          continue;
        }
      }
      try {
        futures.add(custRelay.send(message));
      } catch (err) {
        log(err.toString());
        remove(custRelay.relay.url);
      }
    }
    await Future.wait(futures);
  }

  Future<String> subscribe(
      List<Map<String, dynamic>> filters, Function(Event) onEvent,
      [String? id]) async {
    if (filters.isEmpty) {
      throw ArgumentError("No filters given", "filters");
    }

    final Subscription subscription = Subscription(filters, onEvent, id);
    _subscriptions[subscription.id] = subscription;
    await send(subscription.toJson());
    return subscription.id;
  }

  void unsubscribe(String id) {
    final subscription = _subscriptions.remove(id);
    if (subscription != null) {
      send(["CLOSE", subscription.id]);
    }
  }

  Future<String> query(
      List<Map<String, dynamic>> filters, Function(Event) onEvent,
      [String? id]) async {
    if (filters.isEmpty) {
      throw ArgumentError("No filters given", "filters");
    }
    List<Future<void>> futures = [];
    Subscription subscription = Subscription(filters, onEvent, id);
    for (CustRelay custRelay in _relays.values) {
      if (custRelay.relay.access == WriteAccess.writeOnly) {
        continue;
      }

      custRelay.saveRequest(subscription);

      try {
        futures.add(custRelay.send(subscription.toJson()));
      } catch (err) {
        log(err.toString());
        remove(custRelay.relay.url);
      }
    }
    await Future.wait(futures);
    return subscription.id;
  }

  void _onEvent(CustRelay custRelay, List<dynamic> json) {
    final messageType = json[0];
    if (messageType == 'EVENT') {
      try {
        final event = Event.fromJson(json[2]);
        if (event.isValid &&
            (_doSignatureVerification ? event.isSigned : true)) {
          // add some statistics
          custRelay.relayStatus.noteReceived++;

          event.source = json[3] ?? '';
          final subId = json[1] as String;
          var subscription = _subscriptions[subId];

          if (subscription != null) {
            subscription.onEvent(event);
          } else {
            subscription = custRelay.getRequestSubscription(subId);
            subscription?.onEvent(event);
          }
        }
      } catch (err) {
        log(err.toString());
      }
    } else if (messageType == 'EOSE') {
      if (json.length < 2) {
        log("EOSE result not right.");
        return;
      }

      final subId = json[1] as String;
      custRelay.checkAndCompleteRequest(subId);
    }
  }
}
