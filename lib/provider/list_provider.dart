import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/client/aid.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_util.dart';

import '../client/event_kind.dart';
import '../client/nip04/nip04.dart';
import '../client/nip51/bookmarks.dart';
import '../client/nostr.dart';
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

    Filter filter = Filter();
    filter.kinds = kinds;
    filter.authors = [pubkey];

    if (initQuery) {
      targetNostr!.addInitQuery([filter.toJson()], onEvent);
    } else {
      targetNostr!.query([filter.toJson()], onEvent);
    }
  }

  void onEvent(Event event) {
    var key = "${event.kind}:${event.pubKey}";

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

  // List<String> testAIds = [
  //   "30030:2d5b6404df532de082d9e77f7f4257a6f43fb79bb9de8dd3ac7df5e6d4b500b0:awayuki",
  //   "30030:5b75fd5f49e78191a45e1c9438644fe5d065ea98920c63e9eef86e151e99b809:Party",
  //   "30030:50e8ee3108cdfde4adefe93093cd38bd8692f59f250d3ee4294ef46dc102f370:Suntoshi Emoji",
  //   "30030:03742c205cb6c8d86031c93bc4a9b3d18484c32c86563fc0e218910a2df9aa5d:Notoshi",
  //   "30030:7fa56f5d6962ab1e3cd424e758c3002b8665f7b0d8dcee9fe9e288d7751ac194:twitch",
  //   "30030:6e75f7972397ca3295e0f4ca0fbc6eb9cc79be85bafdd56bd378220ca8eee74e:TheGrinder #ZapStream",
  // ];

  void _handleExtraAndNotify(Event event) {
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
      _bookmarks = parseBookmarks();
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

  void addCustomEmoji(CustomEmoji emoji) {
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
      var result = nostr!.sendEvent(changedEvent);

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

  Bookmarks parseBookmarks() {
    var bookmarks = Bookmarks();
    var bookmarksEvent = getBookmarksEvent();
    if (bookmarksEvent == null) {
      return bookmarks;
    }

    var content = bookmarksEvent.content;
    if (StringUtil.isNotBlank(content)) {
      var agreement = NIP04.getAgreement(nostr!.privateKey!);
      var plainContent = NIP04.decrypt(content, agreement, nostr!.publicKey);

      var jsonObj = jsonDecode(plainContent);
      if (jsonObj is List) {
        List<BookmarkItem> privateItems = [];
        for (var jsonObjItem in jsonObj) {
          if (jsonObjItem is List && jsonObjItem.length > 1) {
            var key = jsonObjItem[0];
            var value = jsonObjItem[1];
            if (key is String && value is String) {
              privateItems.add(BookmarkItem(key: key, value: value));
            }
          }
        }

        bookmarks.privateItems = privateItems;
      }
    }

    List<BookmarkItem> publicItems = [];
    for (var jsonObjItem in bookmarksEvent.tags) {
      if (jsonObjItem is List && jsonObjItem.length > 1) {
        var key = jsonObjItem[0];
        var value = jsonObjItem[1];
        if (key is String && value is String) {
          publicItems.add(BookmarkItem(key: key, value: value));
        }
      }
    }
    bookmarks.publicItems = publicItems;

    return bookmarks;
  }

  void addPrivateBookmark(BookmarkItem bookmarkItem) {
    var bookmarks = getBookmarks();
    bookmarks.privateItems.add(bookmarkItem);
    saveBookmarks(bookmarks);
  }

  void addPublicBookmark(BookmarkItem bookmarkItem) {
    var bookmarks = getBookmarks();
    bookmarks.publicItems.add(bookmarkItem);
    saveBookmarks(bookmarks);
  }

  void removePrivateBookmark(String value) {
    var bookmarks = getBookmarks();
    bookmarks.privateItems.removeWhere((items) {
      return items.value == value;
    });
    saveBookmarks(bookmarks);
  }

  void removePublicBookmark(String value) {
    var bookmarks = getBookmarks();
    bookmarks.publicItems.removeWhere((items) {
      return items.value == value;
    });
    saveBookmarks(bookmarks);
  }

  void saveBookmarks(Bookmarks bookmarks) {
    var content = "";
    if (bookmarks.privateItems.isNotEmpty) {
      List<List> list = [];
      for (var item in bookmarks.privateItems) {
        list.add(item.toJson());
      }

      var agreement = NIP04.getAgreement(nostr!.privateKey!);
      var jsonText = jsonEncode(list);
      content = NIP04.encrypt(jsonText, agreement, nostr!.publicKey);
    }

    List tags = [];
    for (var item in bookmarks.publicItems) {
      tags.add(item.toJson());
    }

    var event =
        Event(nostr!.publicKey, EventKind.BOOKMARKS_LIST, tags, content);
    var resultEvent = nostr!.sendEvent(event);
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

  void clear() {
    _holder.clear();
  }
}
