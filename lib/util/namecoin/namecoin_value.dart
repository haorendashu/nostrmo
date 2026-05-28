import 'dart:convert';

import 'namecoin_identifier.dart';

final RegExp _hexPubKeyRegex = RegExp(r'^[0-9a-fA-F]{64}$');

/// Minimum recursion depth that ifa-0001 §"import" requires
/// implementations to support.
const int defaultImportMaxDepth = 4;

/// A pubkey + optional relays extracted from a Namecoin name value.
class NamecoinNostrEntry {
  /// Lowercase hex-encoded 32-byte public key.
  final String pubkey;

  /// Relay URLs published alongside the pubkey, or empty if none.
  final List<String> relays;

  const NamecoinNostrEntry({required this.pubkey, this.relays = const []});
}

/// Async fetch callback used while walking `import` items. Returns
/// the raw JSON value of the named record, or `null` if the name does
/// not exist / is expired / could not be fetched.
typedef NameValueFetcher = Future<String?> Function(String namecoinName);

/// Pulls the `nostr` pubkey and optional relay list out of a Namecoin
/// name value [valueJson].
///
/// Supports both:
///   * the simple `"nostr": "hex-pubkey"` form, and
///   * the extended `"nostr": { "names": {...}, "relays": {...} }`
///     and `"nostr": { "pubkey": "hex", "relays": [...] }` forms used
///     by Amethyst, Nostur, nostr-tools, dart-nostr.
///
/// When [fetcher] is non-null and the value carries `import` items,
/// imported records are merged shallowly per
/// [ifa-0001](https://github.com/namecoin/proposals/blob/master/ifa-0001.md)
/// §"import" before extraction. The importing object's items always
/// take precedence. Recursion is capped at [defaultImportMaxDepth].
///
/// Returns `null` if the JSON is malformed, has no `nostr` field, or
/// no valid pubkey matches the requested local-part.
Future<NamecoinNostrEntry?> extractNostrFromValue(
  String valueJson,
  ParsedIdentifier parsed, {
  NameValueFetcher? fetcher,
}) async {
  Map<String, dynamic> root;
  try {
    final decoded = json.decode(valueJson);
    if (decoded is! Map<String, dynamic>) return null;
    root = decoded;
  } on FormatException {
    return null;
  }

  // Walk `import` items if a fetcher is available and the record
  // depends on imported state.
  if (fetcher != null && root.containsKey('import')) {
    root = await _expandImports(
      root,
      fetcher,
      depthRemaining: defaultImportMaxDepth,
      visited: <String>{},
    );
  }

  final nostrField = root['nostr'];
  if (nostrField == null) return null;

  // Simple form: "nostr": "hex-pubkey".
  if (nostrField is String) {
    if (parsed.isDomain && parsed.localPart != '_') return null;
    if (!_hexPubKeyRegex.hasMatch(nostrField)) return null;
    return NamecoinNostrEntry(pubkey: nostrField.toLowerCase());
  }

  // Extended form: object with `names`/`pubkey` and optional `relays`.
  if (nostrField is! Map<String, dynamic>) return null;

  if (parsed.isDomain) {
    return _extractFromDomainNamesObject(nostrField, parsed);
  }
  return _extractFromIdentityObject(nostrField, parsed);
}

NamecoinNostrEntry? _extractFromDomainNamesObject(
  Map<String, dynamic> obj,
  ParsedIdentifier parsed,
) {
  final names = obj['names'];

  if (names is Map<String, dynamic>) {
    String? pickedPubkey;
    final exact = names[parsed.localPart];
    if (exact is String && _hexPubKeyRegex.hasMatch(exact)) {
      pickedPubkey = exact;
    } else if (exact != null && parsed.localPart != '_') {
      // Localpart exists but is malformed (not a valid hex pubkey).
      // Treat this as a definitive "no pubkey for this localpart"
      // miss rather than silently falling back to `_`.
      return null;
    } else {
      final underscore = names['_'];
      if (underscore is String && _hexPubKeyRegex.hasMatch(underscore)) {
        pickedPubkey = underscore;
      } else if (parsed.localPart == '_') {
        // Weak fallback: first valid pubkey, only when caller asked
        // for the root identity.
        for (final v in names.values) {
          if (v is String && _hexPubKeyRegex.hasMatch(v)) {
            pickedPubkey = v;
            break;
          }
        }
      }
    }

    if (pickedPubkey != null) {
      final relays = _extractRelays(obj, pickedPubkey);
      return NamecoinNostrEntry(
        pubkey: pickedPubkey.toLowerCase(),
        relays: relays,
      );
    }

    // The `names` map was present but didn't yield a match. Fall
    // through to the single-identity check below only for root
    // lookups so we don't hand `alice@example.bit` the root
    // operator's identity by accident.
    if (parsed.localPart != '_') return null;
  }

  // Single-identity form: `"nostr": { "pubkey": "hex", "relays": [...] }`
  // used by many `d/` records (e.g. `d/mstrofnone`) that publish one
  // identity rather than a `names` map. Only resolves the root.
  if (parsed.localPart == '_') {
    final pk = obj['pubkey'];
    if (pk is String && _hexPubKeyRegex.hasMatch(pk)) {
      final relaysRaw = obj['relays'];
      final relays = relaysRaw is List
          ? relaysRaw.whereType<String>().toList(growable: false)
          : const <String>[];
      return NamecoinNostrEntry(pubkey: pk.toLowerCase(), relays: relays);
    }
  }

  return null;
}

NamecoinNostrEntry? _extractFromIdentityObject(
  Map<String, dynamic> obj,
  ParsedIdentifier parsed,
) {
  // Prefer the `pubkey` field (canonical for `id/` names).
  final pk = obj['pubkey'];
  if (pk is String && _hexPubKeyRegex.hasMatch(pk)) {
    final relaysRaw = obj['relays'];
    final relays = relaysRaw is List
        ? relaysRaw.whereType<String>().toList(growable: false)
        : const <String>[];
    return NamecoinNostrEntry(pubkey: pk.toLowerCase(), relays: relays);
  }

  // Fall back to NIP-05-style `names` with `_` root.
  final names = obj['names'];
  if (names is Map<String, dynamic>) {
    final underscore = names['_'];
    if (underscore is String && _hexPubKeyRegex.hasMatch(underscore)) {
      final relays = _extractRelays(obj, underscore);
      return NamecoinNostrEntry(
        pubkey: underscore.toLowerCase(),
        relays: relays,
      );
    }
  }

  return null;
}

List<String> _extractRelays(Map<String, dynamic> obj, String pubkey) {
  final raw = obj['relays'];
  if (raw is! Map<String, dynamic>) return const [];
  final candidate = raw[pubkey.toLowerCase()] ?? raw[pubkey];
  if (candidate is! List) return const [];
  return candidate.whereType<String>().toList(growable: false);
}

// ---------------------------------------------------------------------
// `import` walking — ifa-0001 §"import"
// ---------------------------------------------------------------------

/// Recursively expand `import` items in [obj]. Returns a new
/// [Map<String, dynamic>] with no `import` key. The importing
/// object's items always take precedence over imported ones; `null`
/// importing items semantically suppress the corresponding imported
/// key (i.e. they remain `null`).
Future<Map<String, dynamic>> _expandImports(
  Map<String, dynamic> obj,
  NameValueFetcher fetcher, {
  required int depthRemaining,
  required Set<String> visited,
}) async {
  if (depthRemaining <= 0) {
    final out = Map<String, dynamic>.from(obj);
    out.remove('import');
    return out;
  }

  final importField = obj['import'];
  final targets = _normaliseImports(importField);
  if (targets.isEmpty) {
    final out = Map<String, dynamic>.from(obj);
    out.remove('import');
    return out;
  }

  // Start with imported items and let the importing object override.
  // Iterate imports in order; later imports override earlier ones,
  // and the importing object overrides everything.
  Map<String, dynamic> merged = <String, dynamic>{};
  for (final t in targets) {
    final key = '${t.name}|${t.selector ?? ''}';
    if (visited.contains(key)) continue;
    final nextVisited = <String>{...visited, key};

    final raw = await fetcher(t.name);
    if (raw == null) continue; // best-effort: skip unreachable imports

    Map<String, dynamic> imported;
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map<String, dynamic>) continue;
      imported = decoded;
    } on FormatException {
      continue;
    }

    // Optional Subdomain Selector: walk the imported `map` tree
    // before merging. (Conservative: skip on any miss.)
    if (t.selector != null && t.selector!.isNotEmpty) {
      final walked = _walkSubdomain(imported, t.selector!.split('.'));
      if (walked == null) continue;
      imported = walked;
    }

    final expanded = await _expandImports(
      imported,
      fetcher,
      depthRemaining: depthRemaining - 1,
      visited: nextVisited,
    );
    for (final entry in expanded.entries) {
      merged[entry.key] = entry.value;
    }
  }

  // Now apply the importing object on top. Keep `null` values
  // (semantic suppression).
  for (final entry in obj.entries) {
    if (entry.key == 'import') continue;
    merged[entry.key] = entry.value;
  }
  return merged;
}

class _ImportTarget {
  final String name;
  final String? selector;
  const _ImportTarget(this.name, this.selector);
}

/// Normalises the three permitted `import` value shapes (canonical
/// array-of-arrays, single-string shorthand, single-array shorthand)
/// into a flat list of [_ImportTarget]s.
List<_ImportTarget> _normaliseImports(dynamic raw) {
  if (raw == null) return const [];
  if (raw is String) return [_ImportTarget(raw, null)];

  if (raw is List) {
    if (raw.isEmpty) return const [];
    final first = raw.first;
    // Shorthand 1: ["d/foo"] or ["d/foo","sub"]
    if (first is String) {
      final name = first;
      final selector =
          raw.length > 1 && raw[1] is String ? raw[1] as String : null;
      return [_ImportTarget(name, selector)];
    }
    // Canonical: [[name], [name, selector], ...]
    final out = <_ImportTarget>[];
    for (final item in raw) {
      if (item is! List || item.isEmpty) continue;
      final name = item.first;
      if (name is! String) continue;
      final selector =
          item.length > 1 && item[1] is String ? item[1] as String : null;
      out.add(_ImportTarget(name, selector));
    }
    return out;
  }

  return const [];
}

/// Walks the `map` tree on [obj] using the dotted [labels]
/// (right-to-left per DNS convention). Returns the resolved object or
/// `null` on any miss. Mirrors the ifa-0001 §"map" exact-label > `*` >
/// `""` resolution order.
Map<String, dynamic>? _walkSubdomain(
  Map<String, dynamic> obj,
  List<String> labels,
) {
  Map<String, dynamic> current = obj;
  // DNS labels are right-to-left, but Selector strings are left-to-
  // right per ifa-0001. Reverse to walk outermost-first.
  final ordered = labels.reversed.toList(growable: false);
  for (final label in ordered) {
    final mapField = current['map'];
    if (mapField is! Map<String, dynamic>) return null;
    final exact = mapField[label];
    final next = exact ?? mapField['*'] ?? mapField[''];
    if (next is! Map<String, dynamic>) return null;
    current = next;
  }
  return current;
}
