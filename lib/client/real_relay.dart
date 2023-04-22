import 'dart:convert';
import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:web_socket_channel/io.dart';
import 'package:nostr_dart/src/relay_info_provider.dart';
import 'package:http/http.dart' as http;

// enum WriteAccess { readOnly, writeOnly, readWrite }

/// Represents an individual relay and manages communications to it.
class RealRelay {
  /// Relay's URL
  final String url;

  /// Relay read/write access configuration
  WriteAccess access;

  /// [NIP-11](https://github.com/nostr-protocol/nips/blob/master/11.md) relay information
  late RelayInfo info;

  late WebSocketHandler _ws;
  Function? _listener;
  Function(String)? onError;
  final RelayInfoProvider _relayInfoProvider;

  /// Creates a `Relay` object.
  ///
  /// [url] is the URL of the relay.
  /// [access] specifies read/write access for the added relay and may be set to
  /// either `WriteAccess.readOnly`, `WriteAccess.writeOnly`, or
  /// `WriteAccess.readWrite`. If not provided the default is read-only.
  /// [relayInfoProvider] is used for testing and not intended for normal use.
  RealRelay(this.url,
      {this.access = WriteAccess.readOnly,
      this.onError,
      RelayInfoProvider? relayInfoProvider})
      : _relayInfoProvider =
            relayInfoProvider ?? RelayInfoProvider(http: http.Client()) {
    _ws = WebSocketHandler(url);
    _ws.addListener(_onData);
  }

  /// Relay connection status. `true` if disconnected.
  bool get isConnected => _ws.isConnected;

  void listen(Function? callback) {
    _listener = callback;
  }

  Future<bool> connect() async {
    bool result = false;
    try {
      info = await _relayInfoProvider.get(url);

      // Relay must support NIP-15 and NIP-20, but NIP-15 had meger into NIP-01
      if (info.nips.contains(20)) {
        await _ws.connect();
        result = true;
      }
    } catch (e) {
      log(e.toString());
    }
    return result;
  }

  Future<void> disconnect() async {
    await _ws.reset();
  }

  Future<void> send(List<dynamic> message) async {
    try {
      final encoded = jsonEncode(message);
      _ws.send(encoded);
    } catch (e) {
      disconnect();
      if (onError != null) {
        onError!(url);
      }
    }
  }

  void _onData(String message) {
    final List<dynamic> json = jsonDecode(message);
    if (json[0] == 'OK' || json[0] == 'EOSE') {
      // notice the request whick want to callback
    }
    if (json[0] == 'NOTICE') {
      log("$url: ${json.toString()}");
    }
    if (_listener != null) {
      json.add(url);
      _listener!(json);
    }
  }
}

class WebSocketHandler {
  final String _url;
  IOWebSocketChannel? _channel;
  bool _connected = false;
  final List<Function> _listeners = [];

  WebSocketHandler(this._url);

  bool get isConnected => _connected;

  Future<void> connect() async {
    reset();
    log("Connecting to $_url");
    _channel = IOWebSocketChannel.connect(_url,
        connectTimeout: const Duration(seconds: 10));
    _connected = true;
    _channel!.stream.listen(_onReceiveMessage, onError: (error) async {
      log("Websocket stream error: $_url");
      await reset();
    }, onDone: () {
      log("Websocket stream closed by remote: $_url");
      _connected = false;
    });
  }

  Future<void> reset() async {
    if (_connected) {
      await _channel!.sink.close();
      _connected = false;
    }
  }

  void send(String message) async {
    if (!_connected) {
      await connect();
    }
    if (_connected) {
      _channel!.sink.add(message);
    }
  }

  addListener(Function callback) {
    _listeners.add(callback);
  }

  removeListener(Function callback) {
    _listeners.remove(callback);
  }

  _onReceiveMessage(message) {
    for (Function callback in _listeners) {
      callback(message);
    }
  }
}
