import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

/// Namecoin script opcodes used by the name-index script and the
/// `NAME_UPDATE` / `NAME_FIRSTUPDATE` outputs. Matches the ElectrumX
/// Namecoin fork (`electrumx/lib/coins.py`) and the Go/Kotlin/
/// Swift/JS/Dart reference implementations of Namecoin NIP-05.
const int opNameUpdate = 0x53; // OP_3, repurposed as OP_NAME_UPDATE.
const int opNameFirstUpdate = 0x52; // OP_2, repurposed as OP_NAME_FIRSTUPDATE.
const int op2Drop = 0x6d;
const int opDrop = 0x75;
const int opReturn = 0x6a;
const int opPushData1 = 0x4c;
const int opPushData2 = 0x4d;
const int opPushData4 = 0x4e;

/// Constructs the canonical script used by the Namecoin ElectrumX
/// fork to index names on-chain.
///
/// Format:
///
///     OP_NAME_UPDATE <push(name)> <push(empty)> OP_2DROP OP_DROP OP_RETURN
///
/// The script's SHA-256, byte-reversed and hex-encoded, is the
/// scripthash queried via `blockchain.scripthash.get_history`.
Uint8List buildNameIndexScript(List<int> nameBytes) {
  final out = <int>[];
  out.add(opNameUpdate);
  _pushData(out, nameBytes);
  _pushData(out, const []);
  out
    ..add(op2Drop)
    ..add(opDrop)
    ..add(opReturn);
  return Uint8List.fromList(out);
}

/// Computes the Electrum-style scripthash: SHA-256 of [script],
/// byte-reversed, then hex-encoded.
String electrumScriptHash(List<int> script) {
  final digest = Uint8List.fromList(sha256.convert(script).bytes);
  for (var i = 0, j = digest.length - 1; i < j; i++, j--) {
    final tmp = digest[i];
    digest[i] = digest[j];
    digest[j] = tmp;
  }
  return hex.encode(digest);
}

/// A parsed Namecoin `NAME_UPDATE` output.
class NameScript {
  /// The name, e.g. `d/example`.
  final String name;

  /// The raw value (typically a JSON payload).
  final String value;

  const NameScript({required this.name, required this.value});
}

/// Extracts the name and value from a `NAME_UPDATE` or
/// `NAME_FIRSTUPDATE` output script.
///
/// Layouts:
///
///     OP_NAME_UPDATE      <push(name)> <push(value)> OP_2DROP OP_DROP <address-script>
///     OP_NAME_FIRSTUPDATE <push(name)> <push(rand)> <push(value)> OP_2DROP OP_2DROP <address-script>
///
/// The leading name/value push-data is decoded; the trailing address
/// script is ignored. Returns `null` if [script] is not one of the
/// two recognised name operations or is malformed.
NameScript? parseNameScript(List<int> script) {
  if (script.isEmpty) return null;
  final op = script[0];
  if (op != opNameUpdate && op != opNameFirstUpdate) return null;

  var pos = 1;
  final nameRead = _readPushData(script, pos);
  if (nameRead == null) return null;
  pos = nameRead.next;

  // NAME_FIRSTUPDATE has an extra <rand> push between name and value;
  // skip it before reading the value.
  if (op == opNameFirstUpdate) {
    final randRead = _readPushData(script, pos);
    if (randRead == null) return null;
    pos = randRead.next;
  }

  final valueRead = _readPushData(script, pos);
  if (valueRead == null) return null;

  try {
    return NameScript(
      name: utf8.decode(nameRead.data, allowMalformed: true),
      value: utf8.decode(valueRead.data, allowMalformed: true),
    );
  } on FormatException {
    return null;
  }
}

void _pushData(List<int> out, List<int> data) {
  final n = data.length;
  if (n < opPushData1) {
    out.add(n);
  } else if (n <= 0xff) {
    out
      ..add(opPushData1)
      ..add(n);
  } else {
    out
      ..add(opPushData2)
      ..add(n & 0xff)
      ..add((n >> 8) & 0xff);
  }
  out.addAll(data);
}

class _PushRead {
  final Uint8List data;
  final int next;
  const _PushRead(this.data, this.next);
}

_PushRead? _readPushData(List<int> script, int pos) {
  if (pos >= script.length) return null;
  final op = script[pos];

  if (op == 0x00) {
    return _PushRead(Uint8List(0), pos + 1);
  }
  if (op < opPushData1) {
    final length = op;
    final end = pos + 1 + length;
    if (end > script.length) return null;
    return _PushRead(Uint8List.fromList(script.sublist(pos + 1, end)), end);
  }
  if (op == opPushData1) {
    if (pos + 2 > script.length) return null;
    final length = script[pos + 1];
    final end = pos + 2 + length;
    if (end > script.length) return null;
    return _PushRead(Uint8List.fromList(script.sublist(pos + 2, end)), end);
  }
  if (op == opPushData2) {
    if (pos + 3 > script.length) return null;
    final length = script[pos + 1] | (script[pos + 2] << 8);
    final end = pos + 3 + length;
    if (end > script.length) return null;
    return _PushRead(Uint8List.fromList(script.sublist(pos + 3, end)), end);
  }
  if (op == opPushData4) {
    if (pos + 5 > script.length) return null;
    final length =
        script[pos + 1] |
        (script[pos + 2] << 8) |
        (script[pos + 3] << 16) |
        (script[pos + 4] << 24);
    final end = pos + 5 + length;
    if (end < 0 || end > script.length) return null;
    return _PushRead(Uint8List.fromList(script.sublist(pos + 5, end)), end);
  }
  return null;
}
