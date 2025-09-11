import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/nip51/bookmarks.dart';
import 'package:nostr_sdk/nip51/group_list.dart';
import 'package:nostr_sdk/nip51/indexer_relay_list.dart';
import 'package:nostr_sdk/nostr.dart';
import 'package:nostrmo/main.dart';

import '../data/custom_emoji.dart';
import '../generated/l10n.dart';

/// Standard list provider.
/// These list usually publish by user himself and the provider will hold the newest one.
class ListProvider extends ChangeNotifier {
  // holder, hold the events.
  // key - “kind:pubkey”, value - event
  final Map<String, Event> _holder = {};

  void load(
    String pubkey,
    List<int> kinds, {
    Nostr? targetNostr,
    bool initQuery = false,
  }) {
    targetNostr ??= nostr;

    List<Map<String, dynamic>> filters = [];
    for (var kind in kinds) {
      Filter filter = Filter();
      filter.kinds = [kind];
      filter.authors = [pubkey];
      filter.limit = 1;

      filters.add(filter.toJson());
    }

    if (initQuery) {
      targetNostr!.addInitQuery(filters, onEvent);
    } else {
      targetNostr!.query(filters, onEvent);
    }
  }

  void onEvent(Event event) {
    var key = "${event.kind}:${event.pubkey}";

    var oldEvent = _holder[key];
    if (oldEvent == null) {
      _holder[key] = event;
      _handleExtraAndNotify(event);
    } else {
      if (event.createdAt > oldEvent.createdAt) {
        _holder[key] = event;
        _handleExtraAndNotify(event);
      }
    }
  }

  void _handleExtraAndNotify(Event event) async {
    if (event.kind == EventKind.EMOJIS_LIST) {
      // This is a emoji list, try to handle some listSet
      for (var tag in event.tags) {
        if (tag is List && tag.length > 1) {
          var k = tag[0];
          var v = tag[1];
          if (k == "a") {
            listSetProvider.getByAId(v);
          }
        }
      }
    } else if (event.kind == EventKind.BOOKMARKS_LIST) {
      // due to bookmarks info will use many times, so it should parse when it was receive.
      var bm = await Bookmarks.parse(event, nostr!);
      if (bm != null) {
        _bookmarks = bm;
      }
    } else if (event.kind == EventKind.GROUP_LIST) {
      _groupList = GroupList.parse(event, nostr!);
      groupDetailsProvider.beginPull(groupIdentifiers);
    } else if (event.kind == EventKind.INDEXER_RELAY_LIST) {
      var indexerRelayList = await IndexerRelayList.parse(event, nostr!);
      if (indexerRelayList != null) {
        _indexerRelayList = indexerRelayList;
      }
    }
    notifyListeners();
  }

  Event? getEmojiEvent() {
    return _holder[emojiKey];
  }

  String get emojiKey {
    return "${EventKind.EMOJIS_LIST}:${nostr!.publicKey}";
  }

  List<MapEntry<String, List<CustomEmoji>>> emojis(S s, Event? emojiEvent) {
    List<MapEntry<String, List<CustomEmoji>>> result = [];

    List<CustomEmoji> list = [];

    if (emojiEvent != null) {
      for (var tag in emojiEvent.tags) {
        if (tag is List && tag.isNotEmpty) {
          var tagKey = tag[0];
          if (tagKey == "emoji" && tag.length > 2) {
            // emoji config config inside.
            var k = tag[1];
            var v = tag[2];
            list.add(CustomEmoji(name: k, filepath: v));
          } else if (tagKey == "a" && tag.length > 1) {
            // emoji config by other listSet
            var aIdStr = tag[1];
            var listSetEvent = listSetProvider.getByAId(aIdStr);
            if (listSetEvent != null) {
              // find the listSet
              var aId = AId.fromString(aIdStr);
              String title = "unknow";
              if (aId != null) {
                title = aId.title;
              }

              List<CustomEmoji> subList = [];
              for (var tag in listSetEvent.tags) {
                if (tag is List && tag.length > 2) {
                  var tagKey = tag[0];
                  var k = tag[1];
                  var v = tag[2];
                  if (tagKey == "emoji") {
                    subList.add(CustomEmoji(name: k, filepath: v));
                  }
                }
              }

              result.add(MapEntry(title, subList));
            }
          }
        }
      }
    }
    result.insert(0, MapEntry(s.Custom, list));
    // for (var testAId in testAIds) {
    //   var listSetEvent = listSetProvider.getByAId(testAId);
    //   if (listSetEvent != null) {
    //     // find the listSet
    //     var aId = AId.fromString(testAId);
    //     String title = "unknow";
    //     if (aId != null) {
    //       title = aId.title;
    //     }

    //     List<CustomEmoji> subList = [];
    //     for (var tag in listSetEvent.tags) {
    //       if (tag is List && tag.length > 2) {
    //         var tagKey = tag[0];
    //         var k = tag[1];
    //         var v = tag[2];
    //         if (tagKey == "emoji") {
    //           subList.add(CustomEmoji(name: k, filepath: v));
    //         }
    //       }
    //     }

    //     result.add(MapEntry(title, subList));
    //   }
    // }

    return result;
  }

  void addCustomEmoji(CustomEmoji emoji) async {
    var cancelFunc = BotToast.showLoading();

    try {
      List<dynamic> tags = [];

      var emojiEvent = getEmojiEvent();
      if (emojiEvent != null) {
        tags.addAll(emojiEvent.tags);
      }
      tags.add(["emoji", emoji.name, emoji.filepath]);
      var changedEvent =
          Event(nostr!.publicKey, EventKind.EMOJIS_LIST, tags, "");
      var result = await nostr!.sendEvent(changedEvent);

      if (result != null) {
        _holder[emojiKey] = result;
        notifyListeners();
      }
    } finally {
      cancelFunc.call();
    }
  }

  Bookmarks _bookmarks = Bookmarks();

  Bookmarks getBookmarks() {
    return _bookmarks;
  }

  String get bookmarksKey {
    return "${EventKind.BOOKMARKS_LIST}:${nostr!.publicKey}";
  }

  Event? getBookmarksEvent() {
    return _holder[bookmarksKey];
  }

  void addPrivateBookmark(BookmarkItem bookmarkItem) {
    _bookmarks.privateItems.add(bookmarkItem);
    saveBookmarks(_bookmarks);
  }

  void addPublicBookmark(BookmarkItem bookmarkItem) {
    _bookmarks.publicItems.add(bookmarkItem);
    saveBookmarks(_bookmarks);
  }

  void removePrivateBookmark(String value) {
    _bookmarks.privateItems.removeWhere((items) {
      return items.value == value;
    });
    saveBookmarks(_bookmarks);
  }

  void removePublicBookmark(String value) {
    _bookmarks.publicItems.removeWhere((items) {
      return items.value == value;
    });
    saveBookmarks(_bookmarks);
  }

  void saveBookmarks(Bookmarks bookmarks) async {
    var event = await bookmarks.toEvent(nostr!);
    if (event == null) {
      BotToast.showText(text: "Bookmark encrypt error");
      return;
    }

    var resultEvent = await nostr!.sendEvent(event);
    if (resultEvent != null) {
      _holder[bookmarksKey] = resultEvent;
    }

    notifyListeners();
  }

  bool checkPublicBookmark(BookmarkItem item) {
    for (var bi in _bookmarks.publicItems) {
      if (bi.value == item.value) {
        return true;
      }
    }

    return false;
  }

  bool checkPrivateBookmark(BookmarkItem item) {
    for (var bi in _bookmarks.privateItems) {
      if (bi.value == item.value) {
        return true;
      }
    }

    return false;
  }

  GroupList _groupList = GroupList();

  List<GroupIdentifier> get groupIdentifiers => _groupList.groupIdentifiers;

  Future<void> joinAndAddGroup(GroupIdentifier gi) async {
    // try to send join messages
    var event = Event(
        nostr!.publicKey,
        EventKind.GROUP_JOIN,
        [
          ["h", gi.groupId]
        ],
        "");
    await nostr!.sendEvent(event, targetRelays: [gi.host], relayTypes: []);

    addGroup(gi);
  }

  void addGroup(GroupIdentifier gi) {
    groupIdentifiers.add(gi);
    _updateGroups();

    groupDetailsProvider.beginPull([gi]);
  }

  void removeGroup(GroupIdentifier gi) {
    groupIdentifiers.removeWhere((groupIdentifier) {
      if (gi.groupId == groupIdentifier.groupId &&
          gi.host == groupIdentifier.host) {
        return true;
      }

      return false;
    });
    _updateGroups();
  }

  void _updateGroups() async {
    var event = await _groupList.toEvent(nostr!);
    var resultEvent = await nostr!.sendEvent(event);

    notifyListeners();
  }

  void clear() {
    _holder.clear();
    _bookmarks = Bookmarks();
    _groupList.clear();
  }

  bool containGroups(GroupIdentifier groupIdentifier) {
    if (groupIdentifiers.isNotEmpty) {
      for (var _groupIdentifier in groupIdentifiers) {
        if (_groupIdentifier.groupId == groupIdentifier.groupId &&
            _groupIdentifier.host == groupIdentifier.host) {
          return true;
        }
      }
    }

    return false;
  }

  IndexerRelayList? _indexerRelayList;

  IndexerRelayList? get indexerRelayList => _indexerRelayList;
}
