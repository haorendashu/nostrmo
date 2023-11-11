import 'dart:convert';
import 'dart:developer';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../consts/client_connected.dart';
import '../data/relay_status.dart';
import 'relay.dart';

class RelayBase extends Relay {
  RelayBase(String url, RelayStatus relayStatus,
      {WriteAccess access = WriteAccess.readWrite})
      : super(url, relayStatus, access: access);

  WebSocketChannel? _wsChannel;

  @override
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
        onError("Websocket error $url", reconnect: true);
      }, onDone: () {
        onError("Websocket stream closed by remote:  $url", reconnect: true);
      });
      relayStatus.connected = ClientConneccted.CONNECTED;
      if (relayStatusCallback != null) {
        relayStatusCallback!();
      }
      return true;
    } catch (e) {
      onError(e.toString(), reconnect: true);
    }
    return false;
  }

  @override
  bool send(List<dynamic> message) {
    if (_wsChannel != null &&
        relayStatus.connected == ClientConneccted.CONNECTED) {
      try {
        final encoded = jsonEncode(message);
        _wsChannel!.sink.add(encoded);
        return true;
      } catch (e) {
        onError(e.toString(), reconnect: true);
      }
    }
    return false;
  }

  @override
  Future<void> disconnect() async {
    try {
      final oldWsChannel = _wsChannel;
      _wsChannel = null;
      await oldWsChannel!.sink.close();
    } catch (e) {}
  }
}
