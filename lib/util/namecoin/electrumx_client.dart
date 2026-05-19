import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'electrumx_server.dart';
import 'namecoin_script.dart';

/// Definitive blockchain answer: the name is not registered.
class NameNotFoundException implements Exception {
  final String name;
  const NameNotFoundException(this.name);

  @override
  String toString() => 'namecoin: name $name not found on Namecoin blockchain';
}

/// Definitive blockchain answer: the name registration has expired.
class NameExpiredException implements Exception {
  final String name;
  const NameExpiredException(this.name);

  @override
  String toString() => 'namecoin: name $name has expired';
}

/// Every configured ElectrumX server failed at the transport level.
class ElectrumxUnreachableException implements Exception {
  final Object? lastError;
  const ElectrumxUnreachableException([this.lastError]);

  @override
  String toString() =>
      'namecoin: all ElectrumX servers unreachable'
      '${lastError != null ? ' (last error: $lastError)' : ''}';
}

/// Abstraction over an ElectrumX RPC client so callers can plug in
/// their own transport (Tor, pinned trust store, custom server list,
/// etc.) without forking the resolver.
abstract class ElectrumxClient {
  /// Returns the raw JSON value stored against [name] on the
  /// Namecoin blockchain. Throws [NameNotFoundException],
  /// [NameExpiredException], or [ElectrumxUnreachableException].
  Future<String> nameShow(String name);

  /// Closes any pooled connections / cancels in-flight calls.
  Future<void> close();
}

/// Default [ElectrumxClient] implementation built on top of
/// `dart:io`'s [WebSocket] transport.
///
/// Each [nameShow] call opens a fresh WebSocket per attempt, matching
/// the Go/Kotlin/Swift/JS/Dart reference implementations. The
/// short-lived per-request model keeps the code small and avoids
/// cross-call interference at the cost of one extra TLS handshake per
/// lookup.
///
/// Failover:
///   * Definitive answers (not found / expired) short-circuit and
///     propagate immediately so callers don't keep hammering peers.
///   * Transport errors (timeout, connection refused, TLS failure)
///     are swallowed and the next server is tried.
///   * If every server fails at the transport level, the last error
///     is wrapped in [ElectrumxUnreachableException].
class DefaultElectrumxClient implements ElectrumxClient {
  /// Servers to try in order.
  final List<ElectrumxServer> servers;

  /// How long to wait for the WebSocket handshake.
  final Duration connectTimeout;

  /// How long to wait for the full request sequence once connected.
  final Duration readTimeout;

  /// Optional pre-built [HttpClient] for the WSS handshake. Pass an
  /// `HttpClient()..badCertificateCallback = ...` here to enable
  /// pinned-certificate trust against self-signed ElectrumX servers.
  /// When `null`, the platform default trust store is used (which
  /// accepts Let's Encrypt and similar public CAs out of the box).
  final HttpClient? httpClient;

  DefaultElectrumxClient({
    this.servers = defaultElectrumxServers,
    this.connectTimeout = const Duration(seconds: 10),
    this.readTimeout = const Duration(seconds: 15),
    this.httpClient,
  });

  @override
  Future<String> nameShow(String name) async {
    Object? lastError;
    var foundDefinitiveMiss = false;

    for (final server in servers) {
      try {
        final value = await _nameShowOn(name, server);
        if (value == null) {
          foundDefinitiveMiss = true;
          continue;
        }
        return value;
      } on NameNotFoundException {
        rethrow;
      } on NameExpiredException {
        rethrow;
      } on _NameMissError {
        foundDefinitiveMiss = true;
        continue;
      } on Object catch (e) {
        lastError = e;
        continue;
      }
    }

    if (foundDefinitiveMiss) throw NameNotFoundException(name);
    throw ElectrumxUnreachableException(lastError);
  }

  @override
  Future<void> close() async {
    httpClient?.close(force: true);
  }

  Future<String?> _nameShowOn(String name, ElectrumxServer server) async {
    // ignore: close_sinks
    final ws = await WebSocket.connect(
      server.url,
      customClient: httpClient,
    ).timeout(connectTimeout);

    final rpc = _Rpc(ws);
    try {
      return await _runFlow(rpc, name).timeout(readTimeout);
    } finally {
      rpc.close();
    }
  }

  Future<String?> _runFlow(_Rpc rpc, String name) async {
    // 1. Negotiate protocol version. The response is discarded; we
    //    only need to confirm the socket is alive.
    await rpc.call('server.version', ['nostrmo-namecoin', '1.4']);

    // 2. Compute the name-index scripthash and fetch its history.
    final script = buildNameIndexScript(utf8.encode(name));
    final scriptHash = electrumScriptHash(script);

    final history = await rpc.call('blockchain.scripthash.get_history', [
      scriptHash,
    ]);
    if (history is! List || history.isEmpty) {
      throw const _NameMissError();
    }
    final latest = history.last;
    if (latest is! Map<String, dynamic>) throw const _NameMissError();
    final txHash = latest['tx_hash'];
    final txHeight = latest['height'];
    if (txHash is! String) throw const _NameMissError();

    // 3. Fetch the verbose transaction.
    final tx = await rpc.call('blockchain.transaction.get', [txHash, true]);
    if (tx is! Map<String, dynamic>) throw const _NameMissError();
    final vouts = tx['vout'];
    if (vouts is! List) throw const _NameMissError();

    // 4. Best-effort expiry check.
    var currentHeight = 0;
    try {
      final header = await rpc.call('blockchain.headers.subscribe', const []);
      if (header is Map<String, dynamic>) {
        final h = header['height'];
        if (h is int) currentHeight = h;
      }
    } on Object {
      // Non-fatal: skip the expiry check.
    }

    if (currentHeight > 0 &&
        txHeight is int &&
        txHeight > 0 &&
        currentHeight - txHeight >= namecoinNameExpireDepth) {
      throw NameExpiredException(name);
    }

    return _extractNameValue(vouts, name);
  }

  /// Walks vouts looking for a NAME_UPDATE matching [name].
  String? _extractNameValue(List<dynamic> vouts, String name) {
    for (final vout in vouts) {
      if (vout is! Map<String, dynamic>) continue;
      final scriptPubKey = vout['scriptPubKey'];
      if (scriptPubKey is! Map<String, dynamic>) continue;
      final hexScript = scriptPubKey['hex'];
      if (hexScript is! String) continue;
      // NAME_UPDATE scripts start with OP_3 (0x53);
      // NAME_FIRSTUPDATE scripts start with OP_2 (0x52). Skip
      // anything else without paying for the hex decode.
      if (!hexScript.startsWith('53') && !hexScript.startsWith('52')) {
        continue;
      }
      List<int> bytes;
      try {
        bytes = _hexToBytes(hexScript);
      } on FormatException {
        continue;
      }
      final parsed = parseNameScript(bytes);
      if (parsed == null) continue;
      if (parsed.name == name) return parsed.value;
    }
    return null;
  }
}

class _NameMissError implements Exception {
  const _NameMissError();
}

/// Minimal JSON-RPC 2.0 client over a [WebSocket].
class _Rpc {
  final WebSocket _ws;
  final Map<int, Completer<dynamic>> _pending = {};
  StreamSubscription<dynamic>? _sub;
  int _nextId = 0;
  bool _closed = false;

  _Rpc(this._ws) {
    _sub = _ws.listen(
      _onMessage,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  Future<dynamic> call(String method, List<dynamic> params) {
    if (_closed) {
      return Future.error(StateError('rpc: connection closed'));
    }
    final id = ++_nextId;
    final completer = Completer<dynamic>();
    _pending[id] = completer;

    final msg = json.encode({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });
    try {
      _ws.add(msg);
    } on Object catch (e) {
      _pending.remove(id);
      completer.completeError(e);
    }
    return completer.future;
  }

  void _onMessage(Object? data) {
    String text;
    if (data is String) {
      text = data;
    } else if (data is List<int>) {
      try {
        text = utf8.decode(data, allowMalformed: false);
      } on FormatException {
        return;
      }
    } else {
      return;
    }

    Map<String, dynamic> parsed;
    try {
      final decoded = json.decode(text);
      if (decoded is! Map<String, dynamic>) return;
      parsed = decoded;
    } on FormatException {
      return;
    }

    final id = parsed['id'];
    if (id is! int) return;
    final completer = _pending.remove(id);
    if (completer == null) return;

    final error = parsed['error'];
    if (error != null) {
      completer.completeError(StateError('rpc error: $error'));
      return;
    }
    completer.complete(parsed['result']);
  }

  void _onError(Object error, StackTrace stackTrace) {
    _failAll(error);
  }

  void _onDone() {
    _failAll(StateError('rpc: connection closed'));
  }

  void _failAll(Object error) {
    final completers = List<Completer<dynamic>>.from(_pending.values);
    _pending.clear();
    for (final c in completers) {
      if (!c.isCompleted) c.completeError(error);
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _failAll(StateError('rpc: closed by caller'));
    unawaited(_sub?.cancel() ?? Future<void>.value());
    unawaited(_ws.close().then<void>((_) {}, onError: (_) {}));
  }
}

List<int> _hexToBytes(String hexStr) {
  if (hexStr.length.isOdd) {
    throw const FormatException('hex string has odd length');
  }
  final bytes = <int>[];
  for (var i = 0; i < hexStr.length; i += 2) {
    final byte = int.parse(hexStr.substring(i, i + 2), radix: 16);
    bytes.add(byte);
  }
  return bytes;
}
