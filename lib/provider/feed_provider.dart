import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/nip19/nip19_tlv.dart';
import 'package:nostr_sdk/nip51/follow_set.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/feed_data_type.dart';
import 'package:nostrmo/main.dart';

import '../consts/feed_source_type.dart';
import '../consts/feed_type.dart';
import '../data/feed_data.dart';

class FeedProvider extends ChangeNotifier {
  static FeedProvider? _feedProvider;

  static Future<FeedProvider> getInstance() async {
    if (_feedProvider == null) {
      _feedProvider = FeedProvider();
      // _settingProvider!._sharedPreferences = await DataUtil.getInstance();
      // await _settingProvider!._init();
      // _settingProvider!._reloadTranslateSourceArgs();
    }
    return _feedProvider!;
  }

  // find the real pubkey from sources and other config.
  void handleFeedData(FeedData feedData) {
    if (feedData.feedType == FeedType.SYNC_FEED) {
      var pubkeys = Set<String>();
      var tags = Set<String>();
      for (var source in feedData.sources) {
        if (source.length <= 1) {
          continue;
        }

        var sourceType = source[0];
        var sourceValue = source[1];
        if (sourceValue is! String || StringUtil.isBlank(sourceValue)) {
          continue;
        }

        if (sourceType == FeedSourceType.PUBKEY) {
          // found the pubkey
          pubkeys.add(sourceValue);
        } else if (sourceType == FeedSourceType.HASH_TAG) {
          // found the topic
          tags.add(sourceValue);
        } else if (sourceType == FeedSourceType.FOLLOWED) {
          var contactList = contactListProvider.contactList;
          if (contactList != null) {
            var contacts = contactList.list();
            for (var contact in contacts) {
              pubkeys.add(contact.publicKey);
            }
            var tagList = contactList.tagList();
            tags.addAll(tagList);
          }
        } else if (sourceType == FeedSourceType.FOLLOW_SET) {
          var naddr = NIP19Tlv.decodeNaddr(sourceValue);
          if (naddr != null && StringUtil.isNotBlank(naddr.id)) {
            var followSet = contactListProvider.followSetMap[naddr.id];
            if (followSet != null) {
              var contacts = followSet.list();
              for (var contact in contacts) {
                pubkeys.add(contact.publicKey);
              }

              var tagList = followSet.tagList();
              tags.addAll(tagList);
            }
          }
        } else if (sourceType == FeedSourceType.FOLLOW_PACKS) {
          var naddr = NIP19Tlv.decodeNaddr(sourceValue);
          if (naddr != null && StringUtil.isNotBlank(naddr.id)) {
            var aid =
                AId(kind: naddr.kind, pubkey: naddr.author, title: naddr.id);
            var event =
                replaceableEventProvider.getEvent(aid, relays: naddr.relays);
            if (event != null && event.kind == EventKind.STARTER_PACKS) {
              var followSet = FollowSet.getPublicFollowSet(event);
              var contacts = followSet.publicContacts;
              for (var contact in contacts) {
                pubkeys.add(contact.publicKey);
              }
            }
          }
        }
      }

      feedData.datas = [];
      for (var tag in tags) {
        feedData.datas.add([FeedDataType.HASH_TAG, tag]);
      }
      for (var pubkey in pubkeys) {
        feedData.datas.add([FeedDataType.PUBKEY, pubkey]);
      }
    }
  }
}
