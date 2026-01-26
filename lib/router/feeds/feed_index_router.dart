import 'package:flutter/material.dart';
import 'package:nostrmo/consts/feed_data_type.dart';
import 'package:nostrmo/consts/feed_source_type.dart';
import 'package:nostrmo/consts/feed_type.dart';
import 'package:nostrmo/router/feeds/relay_feed.dart';
import 'package:provider/provider.dart';

import '../../provider/feed_provider.dart';
import 'empty_feed_page.dart';
import 'mentioned_feed.dart';
import 'sync_feed.dart';

class FeedIndexRouter extends StatefulWidget {
  TabController? tabController;

  FeedIndexRouter({this.tabController});

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

    Widget? main;

    if (feedList.isNotEmpty && widget.tabController != null) {
      List<Widget> feedWidgetList = [];
      var index = 0;
      for (var feed in feedList) {
        if (feed.feedType == FeedType.RELAYS_FEED) {
          feedWidgetList.add(RelayFeed(feed, index));
        } else if (feed.feedType == FeedType.SYNC_FEED) {
          feedWidgetList.add(SyncFeed(feed, index));
        } else if (feed.feedType == FeedType.MENTIONED_FEED) {
          feedWidgetList.add(MentionedFeed(feed, index));
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

      main = TabBarView(
        children: feedWidgetList,
        controller: widget.tabController,
      );
    } else {
      main = EmptyFeedPage();
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: main,
    );
  }
}
