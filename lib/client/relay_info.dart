/// A relay information document
class RelayInfo {
  /// Relay name
  final String name;

  /// Relay description
  final String description;

  /// Nostr public key of the relay admin
  final String pubKey;

  /// Alternative contact of the relay admin
  final String contact;

  /// Nostr Implementation Possibilities supported by the relay
  final List<dynamic> nips;

  /// Relay software description
  final String software;

  /// Relay software version identifier
  final String version;

  RelayInfo._(this.name, this.description, this.pubKey, this.contact, this.nips,
      this.software, this.version);

  factory RelayInfo.fromJson(Map<dynamic, dynamic> json) {
    final String name = json["name"] ?? '';
    final String description = json["description"] ?? "";
    final String pubKey = json["pubkey"] ?? "";
    final String contact = json["contact"] ?? "";
    final List<dynamic> nips = json["supported_nips"] ?? [];
    final String software = json["software"] ?? "";
    final String version = json["version"] ?? "";
    return RelayInfo._(
        name, description, pubKey, contact, nips, software, version);
  }
}
