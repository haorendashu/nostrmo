class FeedSourceType {
  static const int PUBKEY = 1;
  static const int HASH_TAG = 2;

  // feedType relays it was relay,
  static const int FEED_TYPE = 11;
  static const int FOLLOWED = 12;
  static const int FOLLOW_SET = 13;
  static const int FOLLOW_PACKS = 14; // the eventKind STARTER_PACKS
}
