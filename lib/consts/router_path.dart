import 'package:nostrmo/consts/thread_mode.dart';
import 'package:nostrmo/main.dart';

class RouterPath {
  static const String INDEX = "/";
  static const String EDITOR = "/editor";
  static const String DONATE = "/donate";
  static const String NOTICES = "/notices";
  static const String KEY_BACKUP = "/keyBackup";
  static const String RELAYHUB = "/relayhub";
  static const String RELAYS = "/relays";
  static const String FILTER = "/filter";
  static const String USER = "/user";
  static const String PROFILE_EDITOR = "/profileEditor";
  static const String USER_CONTACT_LIST = "/userContactList";
  static const String USER_HISTORY_CONTACT_LIST = "/userHistoryContactList";
  static const String USER_ZAP_LIST = "/userZapList";
  static const String USER_RELAYS = "/userRelays";
  static const String DM_DETAIL = "/dmDetail";
  static const String THREAD_DETAIL = "/threadDetail";
  static const String THREAD_TRACE = "/threadTrace";
  static const String EVENT_DETAIL = "/eventDetail";
  static const String TAG_DETAIL = "/tagDetail";
  static const String SETTING = "/setting";
  static const String QRSCANNER = "/qrScanner";
  static const String WEBUTILS = "/webUtils";
  static const String RELAY_INFO = "/relayInfo";
  static const String FOLLOWED_TAGS_LIST = "/followedTagsList";
  static const String COMMUNITY_DETAIL = "/communityDetail";
  static const String FOLLOWED_COMMUNITIES = "/followedCommunities";
  static const String FOLLOWED = "/followed";
  static const String BOOKMARK = "/bookmark";
  static const String FOLLOW_SET_LIST = "/followSetList";
  static const String FOLLOW_SET_DETAIL = "/followSetDetail";
  static const String FOLLOW_SET_FEED = "/followSetFeed";
  static const String NWC_SETTING = "/nwcSetting";
  static const String GROUP_LIST = "/groupList";
  static const String GROUP_DETAIL = "/groupDetail";

  static String getThreadDetailPath() {
    if (settingProvider.threadMode == ThreadMode.FULL_MODE) {
      return THREAD_DETAIL;
    }

    return THREAD_TRACE;
  }
}
