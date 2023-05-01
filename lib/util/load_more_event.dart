import 'package:flutter/material.dart';
import 'package:nostrmo/data/event_mem_box.dart';

mixin LoadMoreEvent {
  // load more where still left 20 item.
  int loadMoreItemLeftNum = 20;

  int itemLength = 0;

  EventMemBox getEventBox();

  void bindLoadMoreScroll(ScrollController scrollController) {
    scrollController.addListener(() {
      loadMoreScrollCallback(scrollController);
    });
  }

  void loadMoreScrollCallback(ScrollController scrollController) {
    var maxScrollExtent = scrollController.position.maxScrollExtent;
    var offset = scrollController.offset;

    var leftNum = (1 - (offset / maxScrollExtent)) * itemLength;
    // print("maxScrollExtent $maxScrollExtent offset $offset");
    // print("itemLength $itemLength leftNum $leftNum");
    if (leftNum < loadMoreItemLeftNum) {
      loadMore();
    }
  }

  int queryInterval = 1000 * 15;

  int? until;

  int queryLimit = 50;

  DateTime? queryTime;

  int beginQueryNum = 0;

  // this function should be call by user in the build function
  void preBuild() {
    var eventMemBox = getEventBox();
    itemLength = eventMemBox.length();
  }

  // this function call by scroll listener
  void loadMore() {
    // print("touch loadMore");
    var eventMemBox = getEventBox();
    var now = DateTime.now();
    // check if query just now
    if (queryTime != null &&
        now.millisecondsSinceEpoch - queryTime!.millisecondsSinceEpoch <
            queryInterval) {
      return;
    }

    // // check query data length if there was no more event
    // var currentLength = eventMemBox.length();
    // if (currentLength - beginQueryNum == 0) {
    //   // maybe there was no more event
    //   return;
    // }

    // query from the oldest event createdAt
    var oldestEvent = eventMemBox.oldestEvent;
    if (oldestEvent != null) {
      until = oldestEvent.createdAt;
    }

    doQuery();
  }

  // this function should be call by user in the doQuery
  void preQuery() {
    var eventMemBox = getEventBox();
    beginQueryNum = eventMemBox.length();
    queryTime = DateTime.now();
  }

  void doQuery();
}
