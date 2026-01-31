// using to filter some relays. because some relay may not run very well sometime.
class RelayFilter {
  static List<String> relayList = [
    "wheat.happytavern.co", // This relay send unmatch filter event all the time.
  ];

  static bool match(String relayAddr) {
    for (var _blockRelay in relayList) {
      if (relayAddr.contains(_blockRelay)) {
        return true;
      }
    }

    return false;
  }

  static List<String> handle(List<String> relayList) {
    return relayList.where((relay) => !match(relay)).toList();
  }
}
