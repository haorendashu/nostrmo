import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';

import '../client/event_kind.dart' as kind;
import '../client/filter.dart';
import '../data/metadata.dart';
import '../data/metadata_db.dart';
import '../main.dart';
import '../util/lazy_function.dart';
import '../util/string_util.dart';

class MetadataProvider extends ChangeNotifier with LazyFunction {
  Map<String, Metadata> _metadataCache = {};

  static MetadataProvider? _metadataProvider;

  static Future<MetadataProvider> getInstance() async {
    if (_metadataProvider == null) {
      _metadataProvider = MetadataProvider();

      var list = await MetadataDB.all();
      for (var md in list) {
        _metadataProvider!._metadataCache[md.pubKey!] = md;
      }
      // lazyTimeMS begin bigger and request less
      _metadataProvider!.lazyTimeMS = 2000;
    }

    return _metadataProvider!;
  }

  List<String> needUpdatePubKeys = [];

  Metadata? getMetadata(String pubKey) {
    var metadata = _metadataCache[pubKey];
    if (metadata != null) {
      return metadata;
    }

    if (!needUpdatePubKeys.contains(pubKey)) {
      needUpdatePubKeys.add(pubKey);
    }
    lazy(_lazySearch, _lazyComplete);

    return null;
  }

  void _onEvent(Event event) {
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
      notifyListeners();
    } else if (oldMetadata.updated_at! < md.updated_at!) {
      // db
      MetadataDB.update(md);
      // cache
      _metadataCache[md.pubKey!] = md;
      // refresh
      notifyListeners();
    }
  }

  void _lazySearch() {
    var filter = Filter(
        kinds: [kind.EventKind.METADATA], authors: needUpdatePubKeys, limit: 1);
    var subscriptId = StringUtil.rndNameStr(16);
    // use query and close after EOSE
    nostr!.pool.query([filter.toJson()], _onEvent, subscriptId);
  }

  void _lazyComplete() {
    needUpdatePubKeys = [];
  }
}
