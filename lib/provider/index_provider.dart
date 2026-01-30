import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../consts/index_taps.dart';

class IndexProvider extends ChangeNotifier {
  int _currentTap = IndexTaps.FOLLOW;

  int get currentTap => _currentTap;

  IndexProvider({int? indexTap}) {
    if (indexTap != null) {
      _currentTap = indexTap;
    }
  }

  void setCurrentTap(int v) {
    _currentTap = v;
    notifyListeners();
  }

  TabController? _feedsTabController;

  void setFeedsTabController(TabController? feedsTabController) {
    _feedsTabController = feedsTabController;
  }

  // ScrollController? _followPostsScrollController;

  // void setFollowPostsScrollController(
  //     ScrollController? followPostsScrollController) {
  //   _followPostsScrollController = followPostsScrollController;
  // }

  // ScrollController? _followScrollController;

  // void setFollowScrollController(ScrollController? followScrollController) {
  //   _followScrollController = followScrollController;
  // }

  // ScrollController? _mentionedScrollController;

  // void setMentionedScrollController(
  //     ScrollController? mentionedScrollController) {
  //   _mentionedScrollController = mentionedScrollController;
  // }

  // void followScrollToTop() {
  //   if (_feedsTabController != null) {
  //     if (_feedsTabController!.index == 0 &&
  //         _followPostsScrollController != null) {
  //       _followPostsScrollController!.jumpTo(0);
  //     } else if (_feedsTabController!.index == 1 &&
  //         _followScrollController != null) {
  //       _followScrollController!.jumpTo(0);
  //     } else if (_feedsTabController!.index == 2 &&
  //         _mentionedScrollController != null) {
  //       _mentionedScrollController!.jumpTo(0);
  //     }
  //   }
  // }

  Map<int, ItemScrollController> _feedScrollControllerMap = {};

  void setFeedScrollController(
      int index, ItemScrollController scrollController) {
    _feedScrollControllerMap[index] = scrollController;
  }

  void followScrollToTop() {
    if (_feedsTabController != null) {
      var index = _feedsTabController!.index;
      var scrollController = _feedScrollControllerMap[index];

      if (scrollController != null) {
        scrollController.jumpTo(index: 0);
      }
    }
  }

  TabController? _globalTabController;

  void setGlobalTabController(TabController? globalTabController) {
    _globalTabController = globalTabController;
  }

  ScrollController? _eventScrollController;

  void setEventScrollController(ScrollController? eventScrollController) {
    _eventScrollController = eventScrollController;
  }

  ScrollController? _userScrollController;

  void setUserScrollController(ScrollController? userScrollController) {
    _userScrollController = userScrollController;
  }

  void globalScrollToTop() {
    if (_globalTabController != null) {
      if (_globalTabController!.index == 0 && _eventScrollController != null) {
        _eventScrollController!.jumpTo(0);
      } else if (_globalTabController!.index == 1 &&
          _userScrollController != null) {
        _userScrollController!.jumpTo(0);
      }
    }
  }
}
