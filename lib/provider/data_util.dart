import 'package:shared_preferences/shared_preferences.dart';

class DataUtil {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> getInstance() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    return _prefs!;
  }
}

class DataKey {
  static final String SETTING = "setting";

  // static final String RELAYS = "relays";

  static final String CONTACT_LISTS = "contactLists";

  // static final String CONTACT_LIST = "contactList";

  static final String RELAY_LIST = "relayList";

  static final String RELAY_UPDATED_TIME = "relayUpdatedTime";

  static final String BLOCK_LIST = "blockList";

  static final String DIRTYWORD_LIST = "dirtywordList";

  static final String CUSTOM_EMOJI_LIST = "customEmojiList";
}
