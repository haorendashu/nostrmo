class TopicMap {
  static List<List<String>> topicLists = [
    ["nostr", "Nostr", "NOSTR"],
    ["zap", "ZAP", "Zap"],
    ["sats", "Sats", "SATS"],
    ["onlyzap", "onlyZap", "onlyZAP"],
    // client
    ["nostrmo", "Nostrmo", "NostrMo", "NostrMO"],
    ["nostrmofaq", "Nostrmofaq", "NostrmoFAQ"],
    ["Damus", "damus", "DAMUS"],
    ["Amethyst", "amethyst"],
    // coint
    ["Bitcion", "btc", "BTC", "bition"],
    ["nft", "NFT"],
    // country
    ["japan", "jp", "Japan", "JAPAN"],
    ["Zapan", "zapan", "Zapathon", "zapathon"],
    // others
    ["game", "Game", "GAME"],
  ];

  static Map<String, List<String>> topicMap = {};

  static List<String>? getList(String topic) {
    if (topicMap.isEmpty) {
      for (var list in topicLists) {
        for (var t in list) {
          topicMap[t] = list;
        }
      }

      // nips
      for (var i = 0; i < 10; i++) {
        var list = [
          "NIP0$i",
          "NIP-0$i",
          "nip0$i",
          "nip-0$i",
          "Nip0$i",
          "Nip-0$i"
        ];
        for (var t in list) {
          topicMap[t] = list;
        }
      }
      for (var i = 10; i < 100; i++) {
        var list = ["NIP$i", "NIP-$i", "nip$i", "nip-$i", "Nip$i", "Nip-$i"];
        for (var t in list) {
          topicMap[t] = list;
        }
      }
    }

    return topicMap[topic];
  }
}
