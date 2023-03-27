import 'package:flutter/material.dart';

import '../consts/index_Taps.dart';

class IndexProvider extends ChangeNotifier {
  int _currentTap = IndexTaps.FOLLOW;

  int get currentTap => _currentTap;

  void setCurrentTap(int v) {
    _currentTap = v;
    notifyListeners();
  }

  TabController? _followTabController;

  void setFollowTabController(TabController? followTabController) {
    _followTabController = followTabController;
  }

  ScrollController? _followScrollController;

  void setFollowScrollController(ScrollController? followScrollController) {
    _followScrollController = followScrollController;
  }

  ScrollController? _mentionedScrollController;

  void setMentionedScrollController(
      ScrollController? mentionedScrollController) {
    _mentionedScrollController = mentionedScrollController;
  }

  void followScrollToTop() {
    if (_followTabController != null) {
      if (_followTabController!.index == 0 && _followScrollController != null) {
        _followScrollController!.jumpTo(0);
      } else if (_followTabController!.index == 1 &&
          _mentionedScrollController != null) {
        _mentionedScrollController!.jumpTo(0);
      }
    }
  }
}
