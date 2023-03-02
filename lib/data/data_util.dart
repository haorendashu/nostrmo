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
}
