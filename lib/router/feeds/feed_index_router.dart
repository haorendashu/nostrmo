import 'package:flutter/material.dart';
import 'package:nostrmo/consts/feed_data_type.dart';
import 'package:nostrmo/consts/feed_source_type.dart';
import 'package:nostrmo/consts/feed_type.dart';
import 'package:nostrmo/router/feeds/relay_feeds.dart';
import 'package:provider/provider.dart';

import '../../provider/feed_provider.dart';
import 'sync_feed.dart';

class FeedIndexRouter extends StatefulWidget {
  TabController tabController;

  FeedIndexRouter({required this.tabController});

  @override
  State<StatefulWidget> createState() {
    return _FeedIndexRouter();
  }
}

class _FeedIndexRouter extends State<FeedIndexRouter> {
  @override
  Widget build(BuildContext context) {
    var _feedProvider = Provider.of<FeedProvider>(context);
    var feedList = _feedProvider.feedList;

    List<Widget> feedWidgetList = [];
    var index = 0;
    for (var feed in feedList) {
      if (feed.feedType == FeedType.RELAYS_FEED) {
        List<String> relays = [];
        for (var feedSource in feed.sources) {
          if (feedSource.length > 1 &&
              feedSource[0] == FeedSourceType.FEED_TYPE &&
              feedSource[1] is String) {
            relays.add(feedSource[1]);
          }
        }
        feedWidgetList.add(RelayFeeds(relays, index));
      } else if (feed.feedType == FeedType.SYNC_FEED) {
        feedWidgetList.add(SyncFeed(feed.datas, index));
      } else {
        feedWidgetList.add(
          Container(
            width: double.infinity,
            height: 200,
            child: Center(
              child: Text("Feed Type not support"),
            ),
          ),
        );
      }

      index++;
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBarView(
        children: feedWidgetList,
        controller: widget.tabController,
      ),
    );
  }
}
