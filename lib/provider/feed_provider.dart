import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/nip19/nip19_tlv.dart';
import 'package:nostr_sdk/nip51/follow_set.dart';
import 'package:nostr_sdk/nostr.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/feed_data_type.dart';
import 'package:nostrmo/main.dart';

import '../consts/feed_source_type.dart';
import '../consts/feed_type.dart';
import '../data/feed_data.dart';

class FeedProvider extends ChangeNotifier {
  List<FeedData> feedList = [];

  int updateTime = 0;

  void reload({Nostr? targetNostr}) {
    var key = getLocalStoreKey(targetNostr: targetNostr);
    var localJson = sharedPreferences.getString(key);
    if (localJson != null) {
      fromLocalJson(jsonDecode(localJson));
    }
  }

  void saveFeed(FeedData feedData, {Nostr? targetNostr}) {
    _saveToMemery(feedData);

    updateTime = DateTime.now().millisecondsSinceEpoch;
    // update ui
    // save to local
    _saveAndUpdateUI(targetNostr: targetNostr);
    // update to sync task provider
    for (var _fd in feedList) {
      handleFeedData(_fd);
    }
    syncService.updateFromFeedDataList(feedList);
    // send config to relay
  }

  void _saveToMemery(FeedData feedData) {
    bool found = false;
    for (var i = 0; i < feedList.length; i++) {
      var item = feedList[i];
      if (item.id == feedData.id) {
        found = true;
        feedList[i] = feedData;
        break;
      }
    }

    if (!found) {
      feedList.add(feedData);
    }
  }

  String getLocalStoreKey({Nostr? targetNostr}) {
    targetNostr ??= nostr;

    return 'feedList_${targetNostr!.publicKey}';
  }

  void _saveAndUpdateUI({bool updateUI = true, Nostr? targetNostr}) {
    // save to local
    var localJson = toLocalJson();
    var localStoreKey = getLocalStoreKey(targetNostr: targetNostr);

    sharedPreferences.setString(localStoreKey, jsonEncode(localJson));

    if (updateUI) {
      notifyListeners();
    }
  }

  Map<String, dynamic> toLocalJson() {
    Map<String, dynamic> map = {};
    map['updatedList'] = updateTime;
    map['feedList'] = feedList.map((e) => e.toLocalJson()).toList();
    return map;
  }

  void fromLocalJson(Map<String, dynamic> map) {
    var updatedList = map['updatedList'];
    if (updatedList is int) {
      updateTime = updatedList;
    }

    var feedList = map['feedList'];
    if (feedList is List) {
      for (var item in feedList) {
        if (item is Map<String, dynamic>) {
          var feedData = FeedData.fromJson(item);
          _saveToMemery(feedData);
        }
      }
    }
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
