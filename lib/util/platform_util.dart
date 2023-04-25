import 'dart:io';

class PlatformUtil {
  static bool isPC() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}
