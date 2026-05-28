/// Describes a single Namecoin ElectrumX endpoint used for `.bit`
/// NIP-05 resolution.
///
/// Public Namecoin ElectrumX servers expose both a raw TLS port
/// (typically `50002`) and a WebSocket-over-TLS port (typically
/// `port + 4`, so `50006`/`50004`). This resolver always speaks WSS
/// so the same code path works on Flutter mobile, desktop and web.
class ElectrumxServer {
  /// Hostname, e.g. `electrum.nmc.ethicnology.com`.
  final String host;

  /// Port for the WSS endpoint.
  final int port;

  /// WSS path. Defaults to `/`.
  final String path;

  /// `true` if the server uses TLS (`wss://`), `false` for plain
  /// (`ws://`). Defaults to `true`.
  final bool useTls;

  const ElectrumxServer({
    required this.host,
    required this.port,
    this.path = '/',
    this.useTls = true,
  });

  /// Builds the wire URL (e.g. `wss://host:port/`) for this server.
  String get url {
    final scheme = useTls ? 'wss' : 'ws';
    final p = path.startsWith('/') ? path : '/$path';
    return '$scheme://$host:$port$p';
  }

  @override
  String toString() => url;
}

/// Default Namecoin ElectrumX WSS endpoints tried in order with
/// failover.
///
/// Single source of truth for the canonical Namecoin ElectrumX server
/// set is amethyst's quartz module:
///   `quartz/src/commonMain/kotlin/com/vitorpamplona/quartz/`
///       `nip05DnsIdentifiers/namecoin/ElectrumXServer.kt`
///       `DEFAULT_ELECTRUMX_SERVERS`  (6 entries on amethyst's main)
///
/// Every entry below presents a publicly-trusted TLS certificate
/// (Let's Encrypt or similar) so the platform default trust store
/// accepts the handshake unmodified. Servers that serve self-signed
/// certificates are listed as commented-out stubs so a follow-up PR
/// that wires TOFU / TLSA pinning (per the N3 draft in
/// mstrofnone/nips) can uncomment with one line per host. They are
/// not active in v1 because Flutter cert-pinning requires per-platform
/// HttpClient / WebSocket wiring (iOS / Android / macOS / Windows /
/// Linux / Web).
///
/// Amethyst's list also includes two bare-IP entries
/// (`23.158.233.10:50002` and `46.229.238.187:57002`); those don't
/// translate to WSS at all because browsers and Dart's WebSocket
/// stack refuse WSS to bare IPs without an IP-SAN certificate, so
/// they're not listed here even as stubs.
///
/// Callers that want to add their own ElectrumX endpoint can pass a
/// custom list to [NamecoinNip05.valid] / [NamecoinNip05.getPubkey]
/// via the `servers` parameter.
const List<ElectrumxServer> defaultElectrumxServers = [
  // electrumx.testls.space — pinned in amethyst, no public CA chain.
  // ElectrumxServer(host: 'electrumx.testls.space', port: 50004),

  // nmc2.bitcoins.sk — pinned in amethyst, no public CA chain.
  // ElectrumxServer(host: 'nmc2.bitcoins.sk', port: 57004),

  // relay.testls.bit — pinned in amethyst, only .bit-named ElectrumX
  // operator. Requires both TLSA pinning and a .bit hostname resolver.
  // ElectrumxServer(host: 'relay.testls.bit', port: 50004),

  // Operated by @ethicnology (github.com/ethicnology), the same
  // author as the Dart NIP-05 Namecoin reference implementation
  // merged at ethicnology/dart-nostr PR #44. Let's Encrypt cert —
  // the only amethyst default that works with the platform-default
  // trust store. Exposes both 50002 (TLS) and 50004 (WSS).
  ElectrumxServer(host: 'electrum.nmc.ethicnology.com', port: 50004),
];

/// Number of blocks after which a Namecoin name expires if not
/// re-registered (~250 days at 10 minutes/block). Source:
/// `chainparams.cpp → consensus.nNameExpirationDepth` in
/// `namecoin/namecoin-core`.
const int namecoinNameExpireDepth = 36000;
