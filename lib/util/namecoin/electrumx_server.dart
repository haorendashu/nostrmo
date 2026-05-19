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
/// Every entry below presents a publicly-trusted TLS certificate
/// (Let's Encrypt or similar) so the platform default trust store
/// accepts the handshake unmodified. Servers that serve self-signed
/// certificates are kept off this list to avoid having to ship a
/// pinned-certificate trust manager for every supported Flutter
/// platform (TOFU / TLSA pinning is intentionally out of scope for
/// this initial integration — see the README in mstrofnone/nips for
/// the full N3 draft).
///
/// Callers that want to add their own ElectrumX endpoint can pass a
/// custom list to [NamecoinNip05.valid] / [NamecoinNip05.getPubkey]
/// via the `servers` parameter.
const List<ElectrumxServer> defaultElectrumxServers = [
  // Operated by @ethicnology (github.com/ethicnology), the same
  // author as the Dart NIP-05 Namecoin reference implementation
  // merged at ethicnology/dart-nostr PR #44. Let's Encrypt cert,
  // exposes both 50002 (TLS) and 50004 (WSS).
  ElectrumxServer(host: 'electrum.nmc.ethicnology.com', port: 50004),
];

/// Number of blocks after which a Namecoin name expires if not
/// re-registered (~250 days at 10 minutes/block). Source:
/// `chainparams.cpp → consensus.nNameExpirationDepth` in
/// `namecoin/namecoin-core`.
const int namecoinNameExpireDepth = 36000;
