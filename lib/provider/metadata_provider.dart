import 'dart:convert';

import 'package:flutter/material.dart';

import '../client/event_kind.dart' as kind;
import '../client/filter.dart';
import '../data/metadata.dart';
import '../data/metadata_db.dart';
import '../main.dart';
import '../util/string_util.dart';

class MetadataProvider extends ChangeNotifier {
  Map<String, Metadata> _metadataCache = {};

  static MetadataProvider? _metadataProvider;

  static Future<MetadataProvider> getInstance() async {
    if (_metadataProvider == null) {
      _metadataProvider = MetadataProvider();

      var list = await MetadataDB.all();
      for (var md in list) {
        _metadataProvider!._metadataCache[md.pubKey!] = md;
      }
    }

    return _metadataProvider!;
  }

  Metadata? getMetadata(String pubKey) {
    var metadata = _metadataCache[pubKey];
    if (metadata != null) {
      return metadata;
    }

    // TODO need to fix [NOTICE, ERROR: too many concurrent REQs]

    // local not exist, begin to search
    var filter =
        Filter(kinds: [kind.EventKind.METADATA], authors: [pubKey], limit: 1);
    var subScriptId = StringUtil.rndNameStr(16);
    nostr!.pool.subscribe([filter.toJson()], (event) {
      // unsubscribe
      nostr!.pool.unsubscribe(subScriptId);
      // save to local and save to cache
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
    }, subScriptId);

    return null;
  }
}
