import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/event_kind_type.dart';
import 'package:nostrmo/consts/feed_data_event_type.dart';
import 'package:nostrmo/consts/feed_type.dart';
import 'package:nostrmo/consts/feed_source_type.dart';

import '../../consts/router_path.dart';
import '../../data/feed_data.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../util/router_util.dart';

class EmptyFeedPage extends StatefulWidget {
  const EmptyFeedPage({super.key});

  @override
  State<EmptyFeedPage> createState() => _EmptyFeedPageState();
}

class _EmptyFeedPageState extends State<EmptyFeedPage> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var primaryColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;
    var s = S.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Guide icon
          Icon(
            Icons.rss_feed_outlined,
            size: 64,
            color: hintColor,
          ),
          SizedBox(height: 16),

          // Guide title
          Text(
            s.No_feed_yet,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeData.textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 8),

          // Guide description
          Text(
            s.Create_feed_description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: hintColor,
            ),
          ),
          SizedBox(height: 32),

          // Quick add buttons area
          Text(
            "${s.Quickly_createe_a_feed}:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeData.textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 16),

          // Quick add buttons
          _buildQuickAddButtons(context, s),
          SizedBox(height: 24),

          // Or manually create button
          Text(
            s.or,
            style: TextStyle(
              fontSize: 14,
              color: hintColor,
            ),
          ),
          SizedBox(height: 16),

          // Manually create buttons
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                RouterUtil.router(context, RouterPath.FEED_BUILDER);
              },
              child: Text(s.Manually_create_a_custom_feed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButtons(BuildContext context, S s) {
    return Column(
      children: [
        _buildQuickAddButton(
          context: context,
          icon: Icons.people_outline,
          title: s.Followed_Feed,
          subtitle: s.Followed_Feed_descrption,
          feedType: FeedType.SYNC_FEED,
          dataSourceType: FeedSourceType.FOLLOWED,
          onTap: () => _createQuickFeed(
            context,
            "Followed",
            FeedType.SYNC_FEED,
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickAddButton(
          context: context,
          icon: Icons.alternate_email,
          title: s.Mentioned_Feed,
          subtitle: s.Mentioned_Feed_descrption,
          feedType: FeedType.MENTIONED_FEED,
          dataSourceType: null,
          onTap: () => _createQuickFeed(
            context,
            "Mentioned",
            FeedType.MENTIONED_FEED,
          ),
        ),
        const SizedBox(height: 12),
        _buildQuickAddButton(
          context: context,
          icon: Icons.cloud_outlined,
          title: s.Relay_Feed,
          subtitle: s.Relay_Feed_descrption,
          feedType: FeedType.RELAYS_FEED,
          dataSourceType: FeedSourceType.FEED_TYPE,
          onTap: () => _createQuickFeed(
            context,
            "Relay Feed",
            FeedType.RELAYS_FEED,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required int feedType,
    required int? dataSourceType,
    required VoidCallback onTap,
  }) {
    var themeData = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: themeData.cardColor,
        child: Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeData.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: themeData.primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeData.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: themeData.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createQuickFeed(
    BuildContext context,
    String name,
    int feedType,
  ) async {
    var feedData = FeedData(
      StringUtil.rndNameStr(14),
      name,
      feedType,
      eventKinds: EventKindType.SUPPORTED_EVENTS,
      eventType: FeedDataEventType.EVENT_ALL,
      sources: [],
    );

    if (feedType == FeedType.SYNC_FEED) {
      feedData.sources = [
        [FeedSourceType.FOLLOWED, ""]
      ];
    } else if (feedType == FeedType.MENTIONED_FEED) {}

    if (feedType == FeedType.RELAYS_FEED) {
      RouterUtil.router(context, RouterPath.FEED_BUILDER, feedData);
    } else {
      var cancelFunc = BotToast.showLoading();
      try {
        feedProvider.saveFeed(feedData, targetNostr: nostr, updateUI: false);
        if (feedType == FeedType.SYNC_FEED) {
          await Future.delayed(const Duration(seconds: 30));
        }
      } finally {
        cancelFunc();
        feedProvider.updateUI();
      }
    }
  }
}
