import 'dart:convert';
import 'dart:developer';

import 'package:nostrmo/client/relay_info_util.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../consts/client_connected.dart';
import '../data/relay_status.dart';
import 'relay_info.dart';
import 'subscription.dart';

enum WriteAccess { readOnly, writeOnly, readWrite }

class Relay {
  final String url;

  RelayStatus relayStatus;

  WriteAccess access;

  RelayInfo? info;

  Function(Relay, List<dynamic>)? onMessage;

  // quries
  final Map<String, Subscription> _queries = {};

  Relay(this.url, this.relayStatus, {this.access = WriteAccess.readWrite}) {}

  WebSocketChannel? _wsChannel;

  Future<bool> connect() async {
    try {
      relayStatus.connected = ClientConneccted.CONNECTING;
      getRelayInfo(url);

      final wsUrl = Uri.parse(url);
      _wsChannel = WebSocketChannel.connect(wsUrl);
      log("Connect complete!");
      _wsChannel!.stream.listen((message) {
        if (onMessage != null) {
          final List<dynamic> json = jsonDecode(message);
          onMessage!(this, json);
        }
      }, onError: (error) async {
        print(error);
        _onError("Websocket error $url", reconnect: true);
      }, onDone: () {
        _onError("Websocket stream closed by remote:  $url", reconnect: true);
      });
      relayStatus.connected = ClientConneccted.CONNECTED;
      if (relayStatusCallback != null) {
        relayStatusCallback!();
      }
      return true;
    } catch (e) {
      _onError(e.toString(), reconnect: true);
    }
    return false;
  }

  Future<void> getRelayInfo(url) async {
    info = await RelayInfoUtil.get(url);
  }

  bool send(List<dynamic> message) {
    if (_wsChannel != null &&
        relayStatus.connected == ClientConneccted.CONNECTED) {
      try {
        final encoded = jsonEncode(message);
        _wsChannel!.sink.add(encoded);
        return true;
      } catch (e) {
        _onError(e.toString(), reconnect: true);
      }
    }
    return false;
  }

  Future<void> disconnect() async {
    try {
      final oldWsChannel = _wsChannel;
      _wsChannel = null;
      await oldWsChannel!.sink.close();
    } catch (e) {}
  }

  void _onError(String errMsg, {bool reconnect = false}) {
    log("relay error $errMsg");
    relayStatus.error++;
    relayStatus.connected = ClientConneccted.UN_CONNECT;
    if (relayStatusCallback != null) {
      relayStatusCallback!();
    }
    disconnect();

    if (reconnect) {
      Future.delayed(Duration(seconds: 30), () {
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
}
