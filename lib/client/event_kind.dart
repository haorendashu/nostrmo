class EventKind {
  static const int METADATA = 0;

  static const int TEXT_NOTE = 1;

  static const int RECOMMEND_SERVER = 2;

  static const int CONTACT_LIST = 3;

  static const int DIRECT_MESSAGE = 4;

  static const int EVENT_DELETION = 5;

  static const int REPOST = 6;

  static const int REACTION = 7;

  static const int BADGE_AWARD = 8;

  static const int SEAL_EVENT_KIND = 13;

  static const int PRIVATE_DIRECT_MESSAGE = 14;

  static const int GENERIC_REPOST = 16;

  static const int GIFT_WRAP = 1059;

  static const int FILE_HEADER = 1063;

  static const int SHARED_FILE = 1064;

  static const int COMMUNITY_APPROVED = 4550;

  static const int POLL = 6969;

  static const int ZAP_GOALS = 9041;

  static const int ZAP_REQUEST = 9734;

  static const int ZAP = 9735;

  static const int RELAY_LIST_METADATA = 10002;

  static const int BOOKMARKS_LIST = 10003;

  static const int EMOJIS_LIST = 10030;

  static const int AUTHENTICATION = 22242;

  static const int FOLLOW_SETS = 30000;

  static const int BADGE_ACCEPT = 30008;

  static const int BADGE_DEFINITION = 30009;

  static const int LONG_FORM = 30023;

  static const int LONG_FORM_LINKED = 30024;

  static const int COMMUNITY_DEFINITION = 34550;

  static List<int> SUPPORTED_EVENTS = [
    EventKind.TEXT_NOTE,
    EventKind.REPOST,
    EventKind.GENERIC_REPOST,
    EventKind.LONG_FORM,
    EventKind.FILE_HEADER,
    EventKind.SHARED_FILE,
    EventKind.POLL,
    EventKind.ZAP_GOALS,
  ];
}
