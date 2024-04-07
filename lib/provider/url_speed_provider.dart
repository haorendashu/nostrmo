import 'package:flutter/material.dart';
import 'package:nostrmo/util/url_speed_util.dart';

class UrlSpeedProvider extends ChangeNotifier {
  Map<String, int?> _addrSpeedMap = {};

  int? getSpeed(String addr) {
    return _addrSpeedMap[addr];
  }

  Future<int> testSpeed(String addr) async {
    _addrSpeedMap[addr] = -2;
    notifyListeners();
    var speed = await UrlSpeedUtil.test(addr);
    _addrSpeedMap[addr] = speed;
    notifyListeners();
    return speed;
  }
}
