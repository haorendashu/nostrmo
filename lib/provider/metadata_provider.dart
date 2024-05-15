import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip05/nip05_validor.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/nip05status.dart';
import 'package:nostrmo/data/event_db.dart';
import 'package:nostrmo/util/platform_util.dart';

import '../client/event.dart';
import '../client/event_kind.dart' as kind;
import '../client/filter.dart';
import '../client/nip65/relay_list_metadata.dart';
import '../data/metadata.dart';
import '../data/metadata_db.dart';
import '../main.dart';
import '../util/later_function.dart';
import '../util/string_util.dart';

class MetadataProvider extends ChangeNotifier with LaterFunction {
  Map<String, RelayListMetadata> _relayListMetadataCache = {};

  Map<String, Metadata> _metadataCache = {};

  Map<String, int> _handingPubkeys = {};

  static MetadataProvider? _metadataProvider;

  static Future<MetadataProvider> getInstance() async {
    if (_metadataProvider == null) {
      _metadataProvider = MetadataProvider();

      var list = await MetadataDB.all();
      for (var md in list) {
        if (md.valid == Nip05Status.NIP05_NOT_VALIDED) {
          md.valid = null;
        }
        _metadataProvider!._metadataCache[md.pubkey!] = md;
      }

      var relayListMetadataEvents = await EventDB.list(
          Base.RELAY_LIST_METADATA_KEY_INDEX,
          [kind.EventKind.RELAY_LIST_METADATA],
          0,
          1000000);
      for (var relayListMetadataEvent in relayListMetadataEvents) {
        var relayListMetadata =
            RelayListMetadata.fromEvent(relayListMetadataEvent);
        _metadataProvider!._relayListMetadataCache[relayListMetadata.pubkey] =
            relayListMetadata;
      }

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

    if (_penddingEvents.isNotEmpty) {
      _handlePenddingEvents();
    }
  }

  List<String> _needUpdatePubKeys = [];

  void update(String pubkey) {
    if (!_needUpdatePubKeys.contains(pubkey)) {
      _needUpdatePubKeys.add(pubkey);
    }
    later(_laterCallback, null);
  }

  Metadata? getMetadata(String pubkey) {
    var metadata = _metadataCache[pubkey];
    if (metadata != null) {
      return metadata;
    }

    if (!_needUpdatePubKeys.contains(pubkey) &&
        !_handingPubkeys.containsKey(pubkey)) {
      _needUpdatePubKeys.add(pubkey);
    }
    later(_laterCallback, null);

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

  List<Event> _penddingEvents = [];

  void _handlePenddingEvents() {
    for (var event in _penddingEvents) {
      if (StringUtil.isBlank(event.content)) {
        continue;
      }

      _handingPubkeys.remove(event.pubkey);

      var jsonObj = jsonDecode(event.content);
      var md = Metadata.fromJson(jsonObj);
      md.pubkey = event.pubkey;
      md.updated_at = event.createdAt;

      // check cache
      var oldMetadata = _metadataCache[md.pubkey];
      if (oldMetadata == null) {
        // db
        MetadataDB.insert(md);
        // cache
        _metadataCache[md.pubkey!] = md;
        // refresh
      } else if (oldMetadata.updated_at! < md.updated_at!) {
        // db
        MetadataDB.update(md);
        // cache
        _metadataCache[md.pubkey!] = md;
        // refresh
      }
    }
    _penddingEvents.clear;

    notifyListeners();
  }

  void onEvent(Event event) {
    if (event.kind == kind.EventKind.METADATA) {
      _penddingEvents.add(event);
      later(_laterCallback, null);
    } else if (event.kind == kind.EventKind.RELAY_LIST_METADATA) {
      // this is relayInfoMetadata, only set to cache, not update UI
      var oldRelayListMetadata = _relayListMetadataCache[event.pubkey];
      if (oldRelayListMetadata == null) {
        // insert
        EventDB.insert(Base.RELAY_LIST_METADATA_KEY_INDEX, event);
        _eventToRelayListCache(event);
      } else if (event.createdAt > oldRelayListMetadata.createdAt) {
        // update
        EventDB.update(Base.RELAY_LIST_METADATA_KEY_INDEX, event);
        _eventToRelayListCache(event);
      }
    }
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
      var filter = Filter(
          kinds: [kind.EventKind.METADATA, kind.EventKind.RELAY_LIST_METADATA],
          authors: [pubkey]);
      filters.add(filter.toJson());
      if (filters.length > 11) {
        nostr!.query(filters, onEvent);
        filters.clear();
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
    MetadataDB.deleteAll();
  }

  RelayListMetadata? getRelayListMetadata(String pubkey) {
    return _relayListMetadataCache[pubkey];
  }

  void _eventToRelayListCache(Event event) {
    RelayListMetadata rlm = RelayListMetadata.fromEvent(event);
    _relayListMetadataCache[rlm.pubkey] = rlm;
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
