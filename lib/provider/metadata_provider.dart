import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';

import '../client/event_kind.dart' as kind;
import '../client/filter.dart';
import '../data/metadata.dart';
import '../data/metadata_db.dart';
import '../main.dart';
import '../util/later_function.dart';
import '../util/string_util.dart';

class MetadataProvider extends ChangeNotifier with LaterFunction {
  Map<String, Metadata> _metadataCache = {};

  Map<String, int> _handingPubkeys = {};

  static MetadataProvider? _metadataProvider;

  static Future<MetadataProvider> getInstance() async {
    if (_metadataProvider == null) {
      _metadataProvider = MetadataProvider();

      var list = await MetadataDB.all();
      for (var md in list) {
        _metadataProvider!._metadataCache[md.pubKey!] = md;
      }
      // lazyTimeMS begin bigger and request less
      _metadataProvider!.laterTimeMS = 2000;
    }

    return _metadataProvider!;
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

  List<Event> _penddingEvents = [];

  void _handlePenddingEvents() {
    for (var event in _penddingEvents) {
      if (StringUtil.isBlank(event.content)) {
        continue;
      }

      _handingPubkeys.remove(event.pubKey);

      var jsonObj = jsonDecode(event.content);
      var md = Metadata.fromJson(jsonObj);
      md.pubKey = event.pubKey;
      md.updated_at = event.createdAt;

      // check cache
      var oldMetadata = _metadataCache[md.pubKey];
      if (oldMetadata == null) {
        // db
        MetadataDB.insert(md);
        // cache
        _metadataCache[md.pubKey!] = md;
        // refresh
      } else if (oldMetadata.updated_at! < md.updated_at!) {
        // db
        MetadataDB.update(md);
        // cache
        _metadataCache[md.pubKey!] = md;
        // refresh
      }
    }
    _penddingEvents.clear;

    notifyListeners();
  }

  void _onEvent(Event event) {
    _penddingEvents.add(event);
    later(_laterCallback, null);
  }

  void _laterSearch() {
    var filter = Filter(
        kinds: [kind.EventKind.METADATA],
        authors: _needUpdatePubKeys,
        limit: 1);
    var subscriptId = StringUtil.rndNameStr(16);
    // use query and close after EOSE
    nostr!.pool.query([filter.toJson()], _onEvent, subscriptId);

    for (var pubkey in _needUpdatePubKeys) {
      _handingPubkeys[pubkey] = 1;
    }
    _needUpdatePubKeys.clear();
  }
}
