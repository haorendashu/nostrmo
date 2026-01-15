import 'package:flutter/material.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/feed_type.dart';
import 'package:nostrmo/data/feed_data.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/feed_provider.dart';
import 'package:provider/provider.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../consts/feed_data_event_type.dart';
import '../../consts/feed_source_type.dart';
import '../../consts/router_path.dart';
import '../../util/router_util.dart';

class FeedListRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _FeedListRouter();
  }
}

class _FeedListRouter extends State<FeedListRouter> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var _feedProvider = Provider.of<FeedProvider>(context);

    var feedList = _feedProvider.feedList;

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: Text(
          "Feed List",
          style: TextStyle(
            fontSize: themeData.textTheme.bodyLarge!.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.only(
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
              ),
              child: Icon(Icons.add),
            ),
            onPressed: () {
              RouterUtil.router(context, RouterPath.FEED_BUILDER);
            },
          ),
        ],
      ),
      body: feedList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rss_feed,
                    size: 64,
                    color: themeData.hintColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No feeds yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: themeData.hintColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tap the + button to create your first feed",
                    style: TextStyle(
                      fontSize: 14,
                      color: themeData.hintColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(Base.BASE_PADDING),
              itemCount: feedList.length,
              itemBuilder: (context, index) {
                var feed = feedList[index];
                return _buildFeedCard(feed, themeData, index);
              },
            ),
    );
  }

  Widget _buildFeedCard(FeedData feed, ThemeData themeData, int index) {
    var smallFontSize = themeData.textTheme.bodySmall!.fontSize;
    var hintColor = themeData.hintColor;

    List<Widget> infoList = [];

    var rightMargin =
        EdgeInsets.only(left: Base.BASE_PADDING_HALF, right: Base.BASE_PADDING);

    if (feed.feedType == FeedType.SYNC_FEED) {
      if (feed.datas.isNotEmpty) {
        infoList.add(Container(
          child: Icon(
            Icons.person,
            size: smallFontSize,
            color: hintColor,
          ),
        ));
        infoList.add(Container(
          margin: rightMargin,
          child: Text(
            feed.datas.length.toString(),
            style: TextStyle(
              fontSize: smallFontSize,
              color: hintColor,
            ),
          ),
        ));
      }
    } else if (feed.feedType == FeedType.RELAYS_FEED) {
      if (feed.sources.isNotEmpty) {
        List<String> relays = [];
        for (var source in feed.sources) {
          if (source.length > 1) {
            var sourceType = source[0];
            var sourceValue = source[1];
            if (sourceType == FeedSourceType.FEED_TYPE) {
              relays.add(sourceValue);
            }
          }
        }

        if (relays.isNotEmpty) {
          infoList.add(Container(
            child: Text(
              "Relay:",
              style: TextStyle(
                fontSize: smallFontSize,
                color: hintColor,
              ),
            ),
          ));
          infoList.add(Container(
            margin: rightMargin,
            child: Text(
              relays.join(","),
              style: TextStyle(
                fontSize: smallFontSize,
                color: hintColor,
              ),
            ),
          ));
        }
      }
    }

    infoList.add(Container(
      child: Icon(
        Icons.notes,
        size: smallFontSize,
        color: hintColor,
      ),
    ));
    infoList.add(Container(
      margin: rightMargin,
      child: Text(
        getEventType(feed.eventType),
        style: TextStyle(
          fontSize: smallFontSize,
          color: hintColor,
        ),
      ),
    ));

    return Container(
      padding: const EdgeInsets.all(
        Base.BASE_PADDING,
      ),
      margin: const EdgeInsets.only(
        bottom: Base.BASE_PADDING,
      ),
      color: themeData.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  feed.name,
                  style: TextStyle(
                    fontSize: themeData.textTheme.bodyLarge!.fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: themeData.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getFeedTypeName(feed.feedType),
                  style: TextStyle(
                    fontSize: smallFontSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Container(
            child: Row(
              children: infoList,
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              top: Base.BASE_PADDING_HALF,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 18),
                  onPressed: () {
                    _editFeed(feed, context);
                  },
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () {
                    _deleteFeed(feed, context);
                  },
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFeedTypeName(int feedType) {
    switch (feedType) {
      case FeedType.SYNC_FEED:
        return "General Feed";
      case FeedType.RELAYS_FEED:
        return "Relays Feed";
      case FeedType.MENTIONED_FEED:
        return "Mentioned Feed";
      default:
        return "Unknown";
    }
  }

  void _editFeed(FeedData feed, BuildContext context) {
    RouterUtil.router(context, RouterPath.FEED_BUILDER, feed);
  }

  void _deleteFeed(FeedData feed, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Feed"),
        content: Text("Are you sure you want to delete \"${feed.name}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              feedProvider.removeFeed(feed.id);
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String getEventType(int eventType) {
    if (eventType == FeedDataEventType.EVENT_ALL) {
      return "All Events";
    } else if (eventType == FeedDataEventType.EVENT_POST) {
      return "Only Posts";
    } else if (eventType == FeedDataEventType.EVENT_REPLY) {
      return "Only Replies";
    }

    return "unknow";
  }
}
