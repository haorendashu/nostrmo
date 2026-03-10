import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nostr_sdk/utils/string_util.dart';

class SecureStorageUtil {
  static const String _PRIVATE_KEY_MAP_KEY =
      'nostrmo.secure.private_key_map.v1';
  static const String _NWC_URL_MAP_KEY = 'nostrmo.secure.nwc_url_map.v1';
  static const String _MIGRATED_MARK_KEY = 'nostrmo.secure.secret_migrated.v1';
  static const String _PRIVATE_KEY_INDEX_KEY =
      'nostrmo.secure.private_key_index.v1';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<Map<String, String>> readPrivateKeyMap() async {
    return _readMap(_PRIVATE_KEY_MAP_KEY);
  }

  static Future<Map<String, String>> readNwcUrlMap() async {
    return _readMap(_NWC_URL_MAP_KEY);
  }

  static Future<bool> writePrivateKeyMap(Map<String, String> map) async {
    return _writeMapWithVerify(_PRIVATE_KEY_MAP_KEY, map);
  }

  static Future<bool> writeNwcUrlMap(Map<String, String> map) async {
    return _writeMapWithVerify(_NWC_URL_MAP_KEY, map);
  }

  static Future<int?> readPrivateKeyIndex() async {
    try {
      var value = await _storage.read(key: _PRIVATE_KEY_INDEX_KEY);
      if (value == null) return null;
      return int.tryParse(value);
    } catch (e) {
      log('SecureStorageUtil readPrivateKeyIndex error');
      log(e.toString());
      return null;
    }
  }

  static Future<bool> writePrivateKeyIndex(int? index) async {
    try {
      if (index == null) {
        await _storage.delete(key: _PRIVATE_KEY_INDEX_KEY);
      } else {
        await _storage.write(
            key: _PRIVATE_KEY_INDEX_KEY, value: index.toString());
        var saved = await readPrivateKeyIndex();
        return saved == index;
      }
      return true;
    } catch (e) {
      log('SecureStorageUtil writePrivateKeyIndex error');
      log(e.toString());
      return false;
    }
  }

  static Future<bool> isSecretMigrated() async {
    try {
      var value = await _storage.read(key: _MIGRATED_MARK_KEY);
      return value == '1';
    } catch (e) {
      log('SecureStorageUtil isSecretMigrated error');
      log(e.toString());
      return false;
    }
  }

  static Future<void> markSecretMigrated() async {
    try {
      await _storage.write(key: _MIGRATED_MARK_KEY, value: '1');
    } catch (e) {
      log('SecureStorageUtil markSecretMigrated error');
      log(e.toString());
    }
  }

  static Future<Map<String, String>> _readMap(String key) async {
    try {
      var text = await _storage.read(key: key);
      if (StringUtil.isBlank(text)) {
        return {};
      }

      var jsonMap = jsonDecode(text!);
      if (jsonMap is Map<String, dynamic>) {
        Map<String, String> result = {};
        for (var entry in jsonMap.entries) {
          var value = entry.value;
          if (value is String) {
            result[entry.key] = value;
          }
        }
        return result;
      }
    } catch (e) {
      log('SecureStorageUtil readMap error');
      log(e.toString());
    }

    return {};
  }

  static Future<bool> _writeMapWithVerify(
      String key, Map<String, String> map) async {
    try {
      await _storage.write(key: key, value: jsonEncode(map));
      var savedMap = await _readMap(key);
      return mapEquals(savedMap, map);
    } catch (e) {
      log('SecureStorageUtil writeMapWithVerify error');
      log(e.toString());
      return false;
    }
  }
}
