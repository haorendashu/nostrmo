import 'dart:developer';

import '../../consts/client_connected.dart';
import '../../data/relay_status.dart';
import '../subscription.dart';
import 'relay_info.dart';
import 'relay_info_util.dart';

enum WriteAccess { readOnly, writeOnly, readWrite, nothing }

abstract class Relay {
  final String url;

  RelayStatus relayStatus;

  RelayInfo? info;

  Function(Relay, List<dynamic>)? onMessage;

  // quries
  final Map<String, Subscription> _queries = {};

  Relay(this.url, this.relayStatus) {}

  Future<bool> connect() async {
    try {
      return await doConnect();
    } catch (e) {
      print("connect fail");
      disconnect();
      return false;
    }
  }

  Future<bool> doConnect();

  Future<void> getRelayInfo(url) async {
    info ??= await RelayInfoUtil.get(url);
  }

  bool send(List<dynamic> message);

  Future<void> disconnect();

  bool _waitingReconnect = false;

  void onError(String errMsg, {bool reconnect = false}) {
    print("relay error $errMsg");
    relayStatus.error++;
    relayStatus.connected = ClientConneccted.UN_CONNECT;
    if (relayStatusCallback != null) {
      relayStatusCallback!();
    }
    disconnect();

    if (reconnect && !_waitingReconnect) {
      _waitingReconnect = true;
      Future.delayed(const Duration(seconds: 30), () {
        _waitingReconnect = false;
        connect();
      });
    }
  }

  void saveQuery(Subscription subscription) {
    _queries[subscription.id] = subscription;
  }

  bool checkAndCompleteQuery(String id) {
    // all subscription should be close
    var sub = _queries.remove(id);
    if (sub != null) {
      send(["CLOSE", id]);
      return true;
    }
    return false;
  }

  bool checkQuery(String id) {
    return _queries[id] != null;
  }

  Subscription? getRequestSubscription(String id) {
    return _queries[id];
  }

  Function? relayStatusCallback;

  void dispose() {}
}
