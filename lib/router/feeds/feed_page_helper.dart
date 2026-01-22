import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostrmo/consts/feed_data_event_type.dart';
import 'package:nostrmo/data/feed_data.dart';
import 'package:nostrmo/main.dart';

mixin FeedPageHelper {
  FeedData getFeedData();

  List<int> getEventKinds() {
    var feedData = getFeedData();
    return feedData.eventKinds;
  }

  int getOrSetUntilTime() {
    var feedData = getFeedData();
    return feedProvider.getOrSetUntilTime(feedData);
  }

  void updateUntilTime(int untilTime) {
    var feedData = getFeedData();
    feedProvider.setUntilTime(feedData, untilTime);
  }

  bool isSupportedEventType(Event e) {
    var feedData = getFeedData();
    if (feedData.eventType == FeedDataEventType.EVENT_ALL) {
      return true;
    }
    var isPost = eventIsPost(e);
    if (isPost && feedData.eventType == FeedDataEventType.EVENT_POST) {
      return true;
    }
    if (!isPost && feedData.eventType == FeedDataEventType.EVENT_REPLY) {
      return true;
    }

    return false;
  }

  // check if is posts (no tag e and not Mentions, TODO handle NIP27)
  static bool eventIsPost(Event event) {
    if (event.kind == EventKind.COMMENT) {
      return false;
    }

    bool isPosts = true;
    var tagLength = event.tags.length;
    for (var i = 0; i < tagLength; i++) {
      var tag = event.tags[i];
      if (tag.length > 0 && tag[0] == "e") {
        if (event.content.contains("[$i]")) {
          continue;
        }

        isPosts = false;
        break;
      }
    }

    return isPosts;
  }
}
