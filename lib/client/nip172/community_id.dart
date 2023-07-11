class CommunityId {
  late String pubkey;

  late String title;

  static CommunityId? fromString(String text) {
    var strs = text.split(":");
    if (strs.length == 3) {
      return CommunityId(pubkey: strs[1], title: strs[2]);
    }
    return null;
  }

  CommunityId({
    required this.pubkey,
    required this.title,
  });

  String toAString() {
    return "34550:$pubkey:$title";
  }
}
