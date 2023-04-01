import 'dart:developer';

import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/main.dart';

import 'cust_relay.dart';
import 'subscription.dart';

class CustRelayPool {
  // connected relays
  final Map<String, CustRelay> _relays = {};

  // subscription
  final Map<String, Subscription> _subscriptions = {};
  // init query
  final Map<String, Subscription> _initQuery = {};

  final bool _eventVerification;

  CustRelayPool({bool eventVerification = false})
      : _eventVerification = eventVerification;

  List<String> get list => _relays.keys.toList();

  List<String> get subscriptions => _subscriptions.keys.toList();

  Map<String, RelayInfo> get info =>
      _relays.map((key, value) => MapEntry(key, value.relay.info));

  // move to relay provider
  // Map<String, bool> get isConnected =>
  //     _relays.map((key, value) => MapEntry(key, value.relay.isConnected));

  Future<bool> add(
    CustRelay custRelay, {
    bool autoSubscribe = false,
    bool init = false,
  }) async {
    if (_relays.containsKey(custRelay.relay.url)) {
      return true;
    }

    custRelay.relay.onError = (url) {
      log('Could not send or reconnect to relay $url');
      custRelay.relayStatus.error++;
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
      } else if (init) {
        for (Subscription subscription in _initQuery.values) {
          relayDoQuery(custRelay, subscription);
        }
      }

      if (_relayAddedListener != null) {
        _relayAddedListener!(custRelay);
      }
      return true;
    }
    return false;
  }

  void remove(String url) {
    log('Removing $url');
    _relays[url]?.relay.disconnect();
    var relay = _relays.remove(url);
    if (_relayRemovedListener != null && relay != null) {
      _relayRemovedListener!(relay);
    }
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
        custRelay.relayStatus.error++;
        remove(custRelay.relay.url);
      }
    }
    await Future.wait(futures);
  }

  void addInitQuery(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      [String? id]) {
    if (filters.isEmpty) {
      throw ArgumentError("No filters given", "filters");
    }

    final Subscription subscription = Subscription(filters, onEvent, id);
    _initQuery[subscription.id] = subscription;
  }

  /// subscribe shoud be a long time filter search.
  /// like: subscribe the newest event、notice.
  /// subscribe info will hold in reply pool and close in reply pool.
  /// subscribe can be subscribe when new relay put into pool.
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

  /// query should be a one time filter search.
  /// like: query metadata, query old event.
  /// query info will hold in relay and close in relay when EOSE message be received.
  Future<String> query(
      List<Map<String, dynamic>> filters, Function(Event) onEvent,
      [String? id]) async {
    if (filters.isEmpty) {
      throw ArgumentError("No filters given", "filters");
    }
    List<Future<void>> futures = [];
    Subscription subscription = Subscription(filters, onEvent, id);
    for (CustRelay custRelay in _relays.values) {
      // if (custRelay.relay.access == WriteAccess.writeOnly) {
      //   continue;
      // }
      // custRelay.saveQuery(subscription);
      // try {
      //   futures.add(custRelay.send(subscription.toJson()));
      // } catch (err) {
      //   log(err.toString());
      //   custRelay.relayStatus.error++;
      //   remove(custRelay.relay.url);
      // }
      futures.add(relayDoQuery(custRelay, subscription));
    }
    await Future.wait(futures);
    return subscription.id;
  }

  Future<void> relayDoQuery(
      CustRelay custRelay, Subscription subscription) async {
    if (custRelay.relay.access == WriteAccess.writeOnly) {
      return;
    }

    custRelay.saveQuery(subscription);

    try {
      return await custRelay.send(subscription.toJson());
    } catch (err) {
      log(err.toString());
      custRelay.relayStatus.error++;
      remove(custRelay.relay.url);
    }
  }

  void _onEvent(CustRelay custRelay, List<dynamic> json) {
    final messageType = json[0];
    if (messageType == 'EVENT') {
      try {
        final event = Event.fromJson(json[2]);
        if (!_eventVerification || (event.isValid && event.isSigned)) {
          // add some statistics
          custRelay.relayStatus.noteReceived++;

          // check block pubkey
          if (filterProvider.checkBlock(event.pubKey)) {
            return;
          }
          // check dirtyword
          if (filterProvider.checkDirtyword(event.content)) {
            return;
          }

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
      custRelay.checkAndCompleteQuery(subId);
    } else if (messageType == "NOTICE") {
      if (json.length < 2) {
        log("NOTICE result not right.");
        return;
      }

      // notice save, TODO maybe should change code
      noticeProvider.onNotice(custRelay.relay.url, json[1] as String);
    }
  }

  bool checkQueryStatus(String subId) {
    for (CustRelay custRelay in _relays.values) {
      if (custRelay.checkQuery(subId)) {
        return true;
      }
    }

    return false;
  }

  Function(CustRelay)? _relayAddedListener;

  void listenRelayAdded(Function(CustRelay) listener) {
    _relayAddedListener = listener;
  }

  Function(CustRelay)? _relayRemovedListener;

  void listenRelayRemoved(Function(CustRelay) listener) {
    _relayRemovedListener = listener;
  }
}
