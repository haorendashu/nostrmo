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
    // sharedPreferences.remove(key);
    var localJson = sharedPreferences.getString(key);
    if (localJson != null) {
      fromLocalJson(jsonDecode(localJson));
    }
  }

  void removeFeed(String id, {Nostr? targetNostr}) {
    targetNostr ??= nostr;
    feedList.removeWhere((element) => element.id == id);
    _updateFeedList(targetNostr: targetNostr);
  }

  void saveFeed(FeedData feedData, {bool updateUI = true, Nostr? targetNostr}) {
    targetNostr ??= nostr;
    _saveToMemery(feedData);
    _updateFeedList(updateUI: updateUI, targetNostr: targetNostr);
  }

  void _updateFeedList({bool updateUI = true, Nostr? targetNostr}) {
    updateTime = DateTime.now().millisecondsSinceEpoch;
    // update ui
    // update to sync task provider
    for (var _fd in feedList) {
      handleFeedData(_fd);
    }
    // save to local
    _saveAndUpdateUI(updateUI: updateUI, targetNostr: targetNostr);
    syncService.updateFromFeedDataList(feedList, targetNostr!.publicKey);
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

  void updateUI() {
    notifyListeners();
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
        if (source.isEmpty) {
          continue;
        }

        var sourceType = source[0];
        dynamic sourceValue;
        if (sourceType != FeedSourceType.FOLLOWED && source.length >= 2) {
          sourceValue = source[1];
        }
        if (sourceType != FeedSourceType.FOLLOWED &&
            (sourceValue is! String || StringUtil.isBlank(sourceValue))) {
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

  int getOrSetUntilTime(FeedData feedData) {
    var key = "feedUntilTime_${feedData.id}";
    var until = sharedPreferences.getInt(key);
    if (until == null) {
      until = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      sharedPreferences.setInt(key, until);
    }

    return until;
  }

  void setUntilTime(FeedData feedData, int untilTime) {
    var key = "feedUntilTime_${feedData.id}";
    sharedPreferences.setInt(key, untilTime);
  }
}
