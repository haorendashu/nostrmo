import 'dart:developer';

import 'package:nostrmo/util/string_util.dart';

import '../consts/client_connected.dart';
import '../main.dart';
import 'event.dart';
import 'event_kind.dart';
import 'nostr.dart';
import 'relay.dart';
import 'subscription.dart';

class RelayPool {
  Nostr localNostr;

  final Map<String, Relay> _relays = {};

  final bool eventVerification;

  // subscription
  final Map<String, Subscription> _subscriptions = {};

  // init query
  final Map<String, Subscription> _initQuery = {};

  final Map<String, Function> _queryCompleteCallbacks = {};

  RelayPool(this.localNostr, this.eventVerification);

  Future<bool> add(
    Relay relay, {
    bool autoSubscribe = false,
    bool init = false,
  }) async {
    if (_relays.containsKey(relay.url)) {
      return true;
    }
    relay.onMessage = _onEvent;
    // add to pool first and will reconnect by pool
    _relays[relay.url] = relay;

    if (await relay.connect()) {
      if (autoSubscribe) {
        for (Subscription subscription in _subscriptions.values) {
          relay.send(subscription.toJson());
        }
      }
      if (init) {
        for (Subscription subscription in _initQuery.values) {
          relayDoQuery(relay, subscription);
        }
      }

      return true;
    } else {
      print("relay connect fail! ${relay.url}");
    }

    relay.relayStatus.error++;
    return false;
  }

  List<Relay> activeRelays() {
    List<Relay> list = [];
    var it = _relays.values;
    for (var relay in it) {
      if (relay.relayStatus.connected == ClientConneccted.CONNECTED) {
        list.add(relay);
      }
    }
    return list;
  }

  void removeAll() {
    var keys = _relays.keys;
    for (var url in keys) {
      _relays[url]?.disconnect();
      _relays[url]?.dispose();
    }
    _relays.clear();
  }

  void remove(String url) {
    log('Removing $url');
    _relays[url]?.disconnect();
    _relays[url]?.dispose();
    _relays.remove(url);
  }

  Relay? getRelay(String url) {
    return _relays[url];
  }

  bool relayDoQuery(Relay relay, Subscription subscription) {
    if (relay.access == WriteAccess.writeOnly) {
      return false;
    }

    relay.saveQuery(subscription);

    try {
      return relay.send(subscription.toJson());
    } catch (err) {
      log(err.toString());
      relay.relayStatus.error++;
    }

    return false;
  }

  void _onEvent(Relay relay, List<dynamic> json) {
    final messageType = json[0];
    if (messageType == 'EVENT') {
      try {
        final event = Event.fromJson(json[2]);
        if (!eventVerification || (event.isValid && event.isSigned)) {
          // add some statistics
          relay.relayStatus.noteReceived++;

          // check block pubkey
          if (filterProvider.checkBlock(event.pubKey)) {
            return;
          }
          // check dirtyword
          if (filterProvider.checkDirtyword(event.content)) {
            return;
          }

          event.sources.add(relay.url);
          final subId = json[1] as String;
          var subscription = _subscriptions[subId];

          if (subscription != null) {
            subscription.onEvent(event);
          } else {
            subscription = relay.getRequestSubscription(subId);
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
      var isQuery = relay.checkAndCompleteQuery(subId);
      if (isQuery) {
        // is Query find if need to callback
        var callback = _queryCompleteCallbacks[subId];
        if (callback != null) {
          // need to callback, check if all relay complete query
          var it = _relays.values;
          bool completeQuery = true;
          for (var r in it) {
            if (r.checkQuery(subId)) {
              // this relay hadn't compltete query
              completeQuery = false;
              break;
            }
          }
          if (completeQuery) {
            callback();
            _queryCompleteCallbacks.remove(subId);
          }
        }
      }
    } else if (messageType == "NOTICE") {
      if (json.length < 2) {
        log("NOTICE result not right.");
        return;
      }

      // notice save, TODO maybe should change code
      noticeProvider.onNotice(relay.url, json[1] as String);
    } else if (messageType == "AUTH") {
      // auth needed
      if (json.length < 2) {
        log("AUTH result not right.");
        return;
      }
      if (StringUtil.isBlank(localNostr.privateKey)) {
        log("Relay auth fail due to privateKey absent.");
        return;
      }

      final challenge = json[1] as String;
      var tags = [
        ["relay", relay.relayStatus.addr],
        ["challenge", challenge]
      ];
      var event =
          Event(localNostr.publicKey, EventKind.AUTHENTICATION, tags, "");
      event.sign(localNostr.privateKey!);
      relay.send(["AUTH", event.toJson()]);
    }
  }

  void addInitQuery(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    if (filters.isEmpty) {
      throw ArgumentError("No filters given", "filters");
    }

    final Subscription subscription = Subscription(filters, onEvent, id);
    _initQuery[subscription.id] = subscription;
    if (onComplete != null) {
      _queryCompleteCallbacks[subscription.id] = onComplete;
    }
  }

  /// subscribe shoud be a long time filter search.
  /// like: subscribe the newest event、notice.
  /// subscribe info will hold in reply pool and close in reply pool.
  /// subscribe can be subscribe when new relay put into pool.
  String subscribe(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id}) {
    if (filters.isEmpty) {
      throw ArgumentError("No filters given", "filters");
    }

    final Subscription subscription = Subscription(filters, onEvent, id);
    _subscriptions[subscription.id] = subscription;
    send(subscription.toJson());
    return subscription.id;
  }

  void unsubscribe(String id) {
    final subscription = _subscriptions.remove(id);
    if (subscription != null) {
      send(["CLOSE", subscription.id]);
    } else {
      // check query and send close
      var it = _relays.values;
      for (var relay in it) {
        relay.checkAndCompleteQuery(id);
      }
    }
  }

  // different relay use different filter
  String queryByFilters(Map<String, List<Map<String, dynamic>>> filtersMap,
      Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    if (filtersMap.isEmpty) {
      throw ArgumentError("No filters given", "filters");
    }
    id ??= StringUtil.rndNameStr(16);
    if (onComplete != null) {
      _queryCompleteCallbacks[id] = onComplete;
    }
    var entries = filtersMap.entries;
    for (var entry in entries) {
      var url = entry.key;
      var filters = entry.value;

      var relay = _relays[url];
      if (relay != null) {
        Subscription subscription = Subscription(filters, onEvent, id);
        relayDoQuery(relay, subscription);
      }
    }
    return id;
  }

  /// query should be a one time filter search.
  /// like: query metadata, query old event.
  /// query info will hold in relay and close in relay when EOSE message be received.
  String query(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    if (filters.isEmpty) {
      throw ArgumentError("No filters given", "filters");
    }
    Subscription subscription = Subscription(filters, onEvent, id);
    if (onComplete != null) {
      _queryCompleteCallbacks[subscription.id] = onComplete;
    }
    for (Relay relay in _relays.values) {
      relayDoQuery(relay, subscription);
    }
    return subscription.id;
  }

  bool send(List<dynamic> message) {
    bool hadSubmitSend = false;

    for (Relay relay in _relays.values) {
      if (message[0] == "EVENT") {
        if (relay.access == WriteAccess.readOnly) {
          continue;
        }
      }
      if (message[0] == "REQ" || message[0] == "CLOSE") {
        if (relay.access == WriteAccess.writeOnly) {
          continue;
        }
      }
      try {
        var result = relay.send(message);
        if (result) {
          hadSubmitSend = true;
        }
      } catch (err) {
        log(err.toString());
        relay.relayStatus.error++;
      }
    }

    return hadSubmitSend;
  }

  void reconnect() {
    for (var relay in _relays.values) {
      relay.connect();
    }
  }
}
