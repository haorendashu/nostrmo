import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:nostr_sdk/nip02/contact_list.dart';
import 'package:nostr_sdk/nip05/nip05_validor.dart';
import 'package:nostr_sdk/nip65/relay_list_metadata.dart';
import 'package:nostr_sdk/utils/later_function.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/nip05status.dart';
import 'package:nostrmo/data/event_db.dart';

import '../data/metadata.dart';
import '../data/metadata_db.dart';
import '../main.dart';

class MetadataProvider extends ChangeNotifier with LaterFunction {
  Map<String, RelayListMetadata> _relayListMetadataCache = {};

  Map<String, Metadata> _metadataCache = {};

  Map<String, int> _handingPubkeys = {};

  Map<String, ContactList> _contactListMap = {};

  static MetadataProvider? _metadataProvider;

  static Future<MetadataProvider> getInstance() async {
    if (_metadataProvider == null) {
      _metadataProvider = MetadataProvider();
      // lazyTimeMS begin bigger and request less
      _metadataProvider!.laterTimeMS = 2000;
    }

    return _metadataProvider!;
  }

  List<Metadata> findUser(String str, {int? limit = 5}) {
    List<Metadata> list = [];
    if (StringUtil.isNotBlank(str)) {
      var values = _metadataCache.values;
      for (var metadata in values) {
        if ((metadata.displayName != null &&
                metadata.displayName!.contains(str)) ||
            (metadata.name != null && metadata.name!.contains(str))) {
          list.add(metadata);

          if (limit != null && list.length >= limit) {
            break;
          }
        }
      }
    }
    return list;
  }

  void _laterCallback() {
    if (_needUpdatePubKeys.isNotEmpty) {
      _laterSearch();
    }

    if (!_penddingEvents.isEmpty()) {
      _handlePenddingEvents();
    }
  }

  List<String> _checkingFromDBPubKeys = [];

  List<String> _needUpdatePubKeys = [];

  void update(String pubkey) {
    if (!_needUpdatePubKeys.contains(pubkey)) {
      _needUpdatePubKeys.add(pubkey);
    }
    later(_laterCallback);
  }

  void _handleDataNotfound(String pubkey) {
    if (!_checkingFromDBPubKeys.contains(pubkey) &&
        !_needUpdatePubKeys.contains(pubkey) &&
        !_handingPubkeys.containsKey(pubkey)) {
      _checkingFromDBPubKeys.add(pubkey);
      EventDB.list(
          Base.DEFAULT_DATA_INDEX,
          [
            EventKind.METADATA,
            EventKind.RELAY_LIST_METADATA,
            EventKind.CONTACT_LIST,
          ],
          0,
          100,
          pubkeys: [pubkey]).then((eventList) {
        // print("${eventList.length} metadata find from db.");
        _penddingEvents.addList(eventList);
        if (eventList.length < 3) {
          _needUpdatePubKeys.add(pubkey);
        }
        _checkingFromDBPubKeys.remove(pubkey);
        later(_laterCallback);
      });
    }
  }

  Metadata? getMetadata(String pubkey, {bool loadData = true}) {
    var metadata = _metadataCache[pubkey];
    if (metadata != null) {
      return metadata;
    }

    if (loadData) {
      _handleDataNotfound(pubkey);
    }
    return null;
  }

  int getNip05Status(String pubkey) {
    var metadata = getMetadata(pubkey);

    if (PlatformUtil.isWeb()) {
      // web can't valid NIP05 due to cors
      if (metadata != null) {
        if (metadata.nip05 != null) {
          return Nip05Status.NIP05_VALIDED;
        }

        return Nip05Status.NIP05_NOT_VALIDED;
      }

      return Nip05Status.NIP05_NOT_FOUND;
    }

    if (metadata == null) {
      return Nip05Status.METADATA_NOT_FOUND;
    } else if (StringUtil.isNotBlank(metadata.nip05)) {
      if (metadata.valid == null) {
        Nip05Validor.valid(metadata.nip05!, pubkey).then((valid) async {
          if (valid != null) {
            if (valid) {
              metadata.valid = Nip05Status.NIP05_VALIDED;
              await MetadataDB.update(metadata);
            } else {
              // only update cache, next open app vill valid again
              metadata.valid = Nip05Status.NIP05_NOT_VALIDED;
            }
            notifyListeners();
          }
        });

        return Nip05Status.NIP05_NOT_VALIDED;
      } else if (metadata.valid! == Nip05Status.NIP05_VALIDED) {
        return Nip05Status.NIP05_VALIDED;
      }

      return Nip05Status.NIP05_NOT_VALIDED;
    }

    return Nip05Status.NIP05_NOT_FOUND;
  }

  EventMemBox _penddingEvents = EventMemBox(sortAfterAdd: false);

  void _handlePenddingEvents() {
    for (var event in _penddingEvents.all()) {
      _handingPubkeys.remove(event.pubkey);

      if (event.kind == EventKind.METADATA) {
        if (StringUtil.isBlank(event.content)) {
          continue;
        }

        // check cache
        var oldMetadata = _metadataCache[event.pubkey];
        if (oldMetadata == null) {
          // insert
          EventDB.insert(Base.DEFAULT_DATA_INDEX, event);
          _eventToMetadataCache(event);
        } else if (oldMetadata.updated_at! < event.createdAt) {
          // update, remote old event and insert new event
          EventDB.execute(
              "delete from event where key_index = ? and kind = ? and pubkey = ?",
              [Base.DEFAULT_DATA_INDEX, EventKind.METADATA, event.pubkey]);
          EventDB.insert(Base.DEFAULT_DATA_INDEX, event);
          _eventToMetadataCache(event);
        }
      } else if (event.kind == EventKind.RELAY_LIST_METADATA) {
        // this is relayInfoMetadata, only set to cache, not update UI
        var oldRelayListMetadata = _relayListMetadataCache[event.pubkey];
        if (oldRelayListMetadata == null) {
          // insert
          EventDB.insert(Base.DEFAULT_DATA_INDEX, event);
          _eventToRelayListCache(event);
        } else if (event.createdAt > oldRelayListMetadata.createdAt) {
          // update, remote old event and insert new event
          EventDB.execute(
              "delete from event where key_index = ? and kind = ? and pubkey = ?",
              [
                Base.DEFAULT_DATA_INDEX,
                EventKind.RELAY_LIST_METADATA,
                event.pubkey
              ]);
          EventDB.insert(Base.DEFAULT_DATA_INDEX, event);
          _eventToRelayListCache(event);
        }
      } else if (event.kind == EventKind.CONTACT_LIST) {
        var oldContactList = _contactListMap[event.pubkey];
        if (oldContactList == null) {
          // insert
          EventDB.insert(Base.DEFAULT_DATA_INDEX, event);
          _eventToContactList(event);
        } else if (event.createdAt > oldContactList.createdAt) {
          // update, remote old event and insert new event
          EventDB.execute(
              "delete from event where key_index = ? and kind = ? and pubkey = ?",
              [Base.DEFAULT_DATA_INDEX, EventKind.CONTACT_LIST, event.pubkey]);
          EventDB.insert(Base.DEFAULT_DATA_INDEX, event);
          _eventToContactList(event);
        }
      }
    }

    _penddingEvents.clear();
    notifyListeners();
  }

  void onEvent(Event event) {
    _penddingEvents.add(event);
    later(_laterCallback);
  }

  void _laterSearch() {
    if (_needUpdatePubKeys.isEmpty) {
      return;
    }

    // if (!nostr!.readable()) {
    //   // the nostr isn't readable later handle it again.
    //   later(_laterCallback, null);
    //   return;
    // }

    List<Map<String, dynamic>> filters = [];
    for (var pubkey in _needUpdatePubKeys) {
      {
        var filter = Filter(
          kinds: [
            EventKind.METADATA,
          ],
          authors: [pubkey],
          limit: 1,
        );
        filters.add(filter.toJson());
      }
      {
        var filter = Filter(
          kinds: [
            EventKind.RELAY_LIST_METADATA,
          ],
          authors: [pubkey],
          limit: 1,
        );
        filters.add(filter.toJson());
      }
      {
        var filter = Filter(
          kinds: [
            EventKind.CONTACT_LIST,
          ],
          authors: [pubkey],
          limit: 1,
        );
        filters.add(filter.toJson());
      }
      if (filters.length > 20) {
        nostr!.query(filters, onEvent);
        filters = [];
      }
    }
    if (filters.isNotEmpty) {
      nostr!.query(filters, onEvent);
    }

    for (var pubkey in _needUpdatePubKeys) {
      _handingPubkeys[pubkey] = 1;
    }
    _needUpdatePubKeys.clear();
  }

  void clear() {
    _metadataCache.clear();
  }

  ContactList? getContactList(String pubkey, {bool loadData = true}) {
    var contactList = _contactListMap[pubkey];
    if (contactList != null) {
      return contactList;
    }

    if (loadData) {
      _handleDataNotfound(pubkey);
    }
    return null;
  }

  RelayListMetadata? getRelayListMetadata(String pubkey,
      {bool loadData = true}) {
    var relayListMetadata = _relayListMetadataCache[pubkey];
    if (relayListMetadata != null) {
      return relayListMetadata;
    }

    if (loadData) {
      _handleDataNotfound(pubkey);
    }
    return null;
  }

  Future<void> load(List<String> pubkeys) async {
    List<String> needLoadPubkeys = [];
    for (var pubkey in pubkeys) {
      if (_metadataCache[pubkey] == null) {
        needLoadPubkeys.add(pubkey);
      }
    }

    if (needLoadPubkeys.isNotEmpty) {
      var events = await EventDB.list(
          Base.DEFAULT_DATA_INDEX,
          [
            EventKind.METADATA,
            EventKind.RELAY_LIST_METADATA,
            EventKind.CONTACT_LIST,
          ],
          pubkeys: needLoadPubkeys,
          0,
          100000);

      if (events.isNotEmpty) {
        for (var event in events) {
          if (event.kind == EventKind.METADATA) {
            if (StringUtil.isBlank(event.content)) {
              continue;
            }

            var oldMetadata = _metadataCache[event.pubkey];
            if (oldMetadata == null ||
                event.createdAt > oldMetadata.updated_at!) {
              _eventToMetadataCache(event);
            }
          } else if (event.kind == EventKind.RELAY_LIST_METADATA) {
            var oldRelayListMetadata = _relayListMetadataCache[event.pubkey];
            if (oldRelayListMetadata == null ||
                event.createdAt > oldRelayListMetadata.createdAt) {
              _eventToRelayListCache(event);
            }
          } else if (event.kind == EventKind.CONTACT_LIST) {
            var oldContactList = _contactListMap[event.pubkey];
            if (oldContactList == null ||
                event.createdAt > oldContactList.createdAt) {
              _eventToContactList(event);
            }
          }
        }
      }
    }
  }

  void _eventToMetadataCache(Event event) {
    var jsonObj = jsonDecode(event.content);
    var md = Metadata.fromJson(jsonObj);
    md.pubkey = event.pubkey;
    md.updated_at = event.createdAt;
    _metadataCache[event.pubkey] = md;
  }

  void _eventToRelayListCache(Event event) {
    RelayListMetadata rlm = RelayListMetadata.fromEvent(event);
    _relayListMetadataCache[rlm.pubkey] = rlm;
  }

  void _eventToContactList(Event event) {
    var contactList = ContactList.fromJson(event.tags, event.createdAt);
    _contactListMap[event.pubkey] = contactList;
  }

  List<String> getExtralRelays(String pubkey, bool isWrite) {
    List<String> tempRelays = [];
    var relayListMetadata = metadataProvider.getRelayListMetadata(pubkey);
    if (relayListMetadata != null) {
      late List<String> relays;
      if (isWrite) {
        relays = relayListMetadata.writeAbleRelays;
      } else {
        relays = relayListMetadata.readAbleRelays;
      }
      tempRelays = nostr!.getExtralReadableRelays(relays, 3);
    }
    return tempRelays;
  }
}
