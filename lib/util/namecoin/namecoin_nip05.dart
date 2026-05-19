import 'electrumx_client.dart';
import 'electrumx_server.dart';
import 'namecoin_identifier.dart';
import 'namecoin_value.dart';

/// Namecoin-backed NIP-05 resolver for `.bit` addresses, mirroring
/// the signature of `Nip05Validor` from the `nostr_sdk` package so it
/// can be used as a drop-in branch from call sites that already
/// dispatch on the existing NIP-05 path.
///
/// Where `Nip05Validor` resolves `alice@example.com` against
/// `https://example.com/.well-known/nostr.json`, [NamecoinNip05]
/// resolves `alice@example.bit` (and `d/<name>` / `id/<name>`)
/// against the corresponding record on the Namecoin blockchain via a
/// public ElectrumX server.
///
/// Both value shapes documented in the `.bit` NIP-05 draft are
/// accepted:
///
///   * the simple `"nostr": "hex-pubkey"` form, and
///   * the extended `"nostr": { "names": {...}, "relays": {...} }`
///     form used by Amethyst, Nostur, nostr-tools and dart-nostr.
///
/// `import` items in the Namecoin record are walked per
/// [ifa-0001](https://github.com/namecoin/proposals/blob/master/ifa-0001.md)
/// §"import" so identities can be factored across multiple Namecoin
/// names.
class NamecoinNip05 {
  static final Map<String, int> _checking = <String, int>{};

  /// Returns `true` when [identifier] should be routed to Namecoin
  /// resolution. Cheap check, safe to call on hot paths.
  static bool isBit(String? identifier) => isBitIdentifier(identifier);

  /// Verifies [nip05Address] resolves to [pubkey] on the Namecoin
  /// blockchain. Returns:
  ///
  ///   * `true`  when the on-chain record matches,
  ///   * `false` when the record does not match,
  ///   * `null`  when a verification of the same address is already
  ///             in flight (matches `Nip05Validor.valid`).
  static Future<bool?> valid(
    String nip05Address,
    String pubkey, {
    List<ElectrumxServer>? servers,
  }) async {
    if (_checking[nip05Address] != null) {
      return null;
    }
    try {
      _checking[nip05Address] = 1;
      return await _doValid(nip05Address, pubkey, servers);
    } finally {
      _checking.remove(nip05Address);
    }
  }

  static Future<bool> _doValid(
    String nip05Address,
    String pubkey,
    List<ElectrumxServer>? servers,
  ) async {
    final remote = await getPubkey(nip05Address, servers: servers);
    if (remote == null) return false;
    return remote.toLowerCase() == pubkey.toLowerCase();
  }

  /// Returns the lowercase hex pubkey published for [nip05Address] on
  /// the Namecoin blockchain, or `null` if the identifier is not a
  /// valid `.bit` shape, the name is unregistered/expired, the record
  /// lacks a `nostr` field for the requested local-part, or every
  /// configured ElectrumX server failed.
  static Future<String?> getPubkey(
    String nip05Address, {
    List<ElectrumxServer>? servers,
  }) async {
    final parsed = parseNamecoinIdentifier(nip05Address);
    if (parsed == null) return null;

    final client = DefaultElectrumxClient(
      servers: servers ?? defaultElectrumxServers,
    );
    try {
      Future<String?> fetcher(String namecoinName) async {
        try {
          return await client.nameShow(namecoinName);
        } on Exception {
          return null;
        }
      }

      String valueJson;
      try {
        valueJson = await client.nameShow(parsed.namecoinName);
      } on Exception {
        return null;
      }

      final entry = await extractNostrFromValue(
        valueJson,
        parsed,
        fetcher: fetcher,
      );
      return entry?.pubkey;
    } finally {
      await client.close();
    }
  }

  /// Returns the lowercase hex pubkey and any relays published for
  /// [nip05Address] on the Namecoin blockchain. Returns `null` on the
  /// same failure conditions as [getPubkey].
  ///
  /// Surfaced as a separate entry point so callers that care about
  /// the published relay list (e.g. relay-list seeding) can read it
  /// without having to repeat the lookup.
  static Future<NamecoinNostrEntry?> resolve(
    String nip05Address, {
    List<ElectrumxServer>? servers,
  }) async {
    final parsed = parseNamecoinIdentifier(nip05Address);
    if (parsed == null) return null;

    final client = DefaultElectrumxClient(
      servers: servers ?? defaultElectrumxServers,
    );
    try {
      Future<String?> fetcher(String namecoinName) async {
        try {
          return await client.nameShow(namecoinName);
        } on Exception {
          return null;
        }
      }

      String valueJson;
      try {
        valueJson = await client.nameShow(parsed.namecoinName);
      } on Exception {
        return null;
      }

      return extractNostrFromValue(valueJson, parsed, fetcher: fetcher);
    } finally {
      await client.close();
    }
  }
}
