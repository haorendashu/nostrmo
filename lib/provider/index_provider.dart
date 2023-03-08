import 'package:flutter/material.dart';

import '../consts/index_Taps.dart';

class IndexProvider extends ChangeNotifier {
  int _currentTap = IndexTaps.FOLLOW;

  int get currentTap => _currentTap;

  void setCurrentTap(int v) {
    // if (v == IndexTaps.FOLLOW) {
    //   _currentTap = IndexTaps.FOLLOW;
    // } else if (v == IndexTaps.DM) {
    //   _currentTap = IndexTaps.DM;
    // } else if (v == IndexTaps.SEARCH) {
    //   _currentTap = IndexTaps.SEARCH;
    // } else if (v == IndexTaps.NOTICE) {
    //   _currentTap = IndexTaps.NOTICE;
    // }
    _currentTap = v;
    notifyListeners();
  }
}
