import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/utils/encrypt_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../consts/base.dart';
import 'secure_storage_util.dart';
import 'setting_provider.dart';

class SecureProvider extends ChangeNotifier {
  static SecureProvider? _instance;

  Map<String, String> _privateKeyMap = {};
  Map<String, String> _nwcUrlMap = {};
  int? _privateKeyIndex;
  bool _useSecureStorage = false;

  static Future<SecureProvider> getInstance() async {
    if (_instance == null) {
      _instance = SecureProvider();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _privateKeyMap.clear();
    _nwcUrlMap.clear();

    var securePrivateKeyMap = await SecureStorageUtil.readPrivateKeyMap();
    var secureNwcUrlMap = await SecureStorageUtil.readNwcUrlMap();
    var secretMigrated = await SecureStorageUtil.isSecretMigrated();
    _privateKeyIndex = await SecureStorageUtil.readPrivateKeyIndex();

    if (secretMigrated ||
        securePrivateKeyMap.isNotEmpty ||
        secureNwcUrlMap.isNotEmpty) {
      _useSecureStorage = true;
      _privateKeyMap.addAll(securePrivateKeyMap);
      _nwcUrlMap.addAll(secureNwcUrlMap);
      return;
    }

    _useSecureStorage = true;
    await SecureStorageUtil.markSecretMigrated();
  }

  Future<void> migrateLegacyData(SettingProvider settingProvider) async {
    // Decode legacy data from SettingProvider
    var legacyPrivateKeyMap = await _decodeLegacyPrivateKeyMap(settingProvider);
    var legacyNwcUrlMap = await _decodeLegacyNwcUrlMap(settingProvider);

    if (legacyPrivateKeyMap.isEmpty && legacyNwcUrlMap.isEmpty) {
      return;
    }

    // Migrate privateKeyIndex if not yet stored in secure storage
    if (_privateKeyIndex == null) {
      var legacyIndex = settingProvider.settingData.privateKeyIndex;
      if (legacyIndex != null) {
        _privateKeyIndex = legacyIndex;
        await SecureStorageUtil.writePrivateKeyIndex(legacyIndex);
      }
    }

    var mergedPrivateKeyMap = <String, String>{};
    mergedPrivateKeyMap.addAll(_privateKeyMap);
    mergedPrivateKeyMap.addAll(legacyPrivateKeyMap);

    var mergedNwcUrlMap = <String, String>{};
    mergedNwcUrlMap.addAll(_nwcUrlMap);
    mergedNwcUrlMap.addAll(legacyNwcUrlMap);

    // Attempt to write to secure storage
    var privateKeyWriteResult =
        await SecureStorageUtil.writePrivateKeyMap(mergedPrivateKeyMap);
    var nwcWriteResult =
        await SecureStorageUtil.writeNwcUrlMap(mergedNwcUrlMap);

    if (privateKeyWriteResult && nwcWriteResult) {
      _useSecureStorage = true;
      _privateKeyMap
        ..clear()
        ..addAll(mergedPrivateKeyMap);
      _nwcUrlMap
        ..clear()
        ..addAll(mergedNwcUrlMap);
      await SecureStorageUtil.markSecretMigrated();

      // Clear legacy data from SettingProvider
      await settingProvider.clearLegacySecretData();
      notifyListeners();
      return;
    }

    // Fallback to in-memory storage if secure storage fails
    _useSecureStorage = false;
    _privateKeyMap
      ..clear()
      ..addAll(mergedPrivateKeyMap);
    _nwcUrlMap
      ..clear()
      ..addAll(mergedNwcUrlMap);
    notifyListeners();
  }

  Future<Map<String, String>> _decodeLegacyPrivateKeyMap(
      SettingProvider settingProvider) async {
    Map<String, String> result = {};
    var settingData = settingProvider.settingData;
    String? privateKeyMapText = settingData.encryptPrivateKeyMap;

    try {
      if (StringUtil.isNotBlank(privateKeyMapText)) {
        privateKeyMapText = await EncryptUtil.aesDecrypt(
            privateKeyMapText!, Base.KEY_EKEY, Base.KEY_IV);
      } else if (StringUtil.isNotBlank(settingData.privateKeyMap) &&
          StringUtil.isBlank(settingData.encryptPrivateKeyMap)) {
        privateKeyMapText = settingData.privateKeyMap;
      }
    } catch (e) {
      log("SecureProvider: handle privateKey error");
      log(e.toString());
    }

    if (StringUtil.isNotBlank(privateKeyMapText)) {
      try {
        var jsonKeyMap = jsonDecode(privateKeyMapText!);
        if (jsonKeyMap != null) {
          for (var entry in (jsonKeyMap as Map<String, dynamic>).entries) {
            result[entry.key] = entry.value;
          }
        }
      } catch (e) {
        log("SecureProvider: privateKeyMap jsonDecode error");
        log(e.toString());
      }
    }

    return result;
  }

  Future<Map<String, String>> _decodeLegacyNwcUrlMap(
      SettingProvider settingProvider) async {
    Map<String, String> result = {};
    var settingData = settingProvider.settingData;
    var nwcUrlMap = settingData.nwcUrlMap;

    if (StringUtil.isNotBlank(nwcUrlMap)) {
      try {
        nwcUrlMap = await EncryptUtil.aesDecrypt(
            nwcUrlMap!, Base.KEY_EKEY, Base.KEY_IV);
        var jsonKeyMap = jsonDecode(nwcUrlMap);
        if (jsonKeyMap != null) {
          for (var entry in (jsonKeyMap as Map<String, dynamic>).entries) {
            result[entry.key] = entry.value;
          }
        }
      } catch (e) {
        log("SecureProvider: nwcUrlMap jsonDecode error");
        log(e.toString());
      }
    }

    return result;
  }

  int? get privateKeyIndex => _privateKeyIndex;

  Future<void> setPrivateKeyIndex(int? index) async {
    _privateKeyIndex = index;
    await SecureStorageUtil.writePrivateKeyIndex(index);
    notifyListeners();
  }

  Map<String, String> get privateKeyMap => _privateKeyMap;

  String? getPrivateKey(int? index) {
    if (index != null && _privateKeyMap.isNotEmpty) {
      return _privateKeyMap[index.toString()];
    }
    return null;
  }

  Future<int> addAndChangePrivateKey(String pk) async {
    int? findIndex;
    var entries = _privateKeyMap.entries;
    for (var entry in entries) {
      if (entry.value == pk) {
        findIndex = int.tryParse(entry.key);
        break;
      }
    }
    if (findIndex != null) {
      _privateKeyIndex = findIndex;
      await SecureStorageUtil.writePrivateKeyIndex(findIndex);
      notifyListeners();
      return findIndex;
    }

    for (var i = 0; i < 20; i++) {
      var index = i.toString();
      var _pk = _privateKeyMap[index];
      if (_pk == null) {
        _privateKeyMap[index] = pk;
        _privateKeyIndex = i;
        await _encodePrivateKeyMap();
        await SecureStorageUtil.writePrivateKeyIndex(i);
        notifyListeners();
        return i;
      }
    }

    return -1;
  }

  Future<void> _encodePrivateKeyMap() async {
    if (_useSecureStorage) {
      var result = await SecureStorageUtil.writePrivateKeyMap(_privateKeyMap);
      if (!result) {
        _useSecureStorage = false;
        log('SecureProvider: failed to write to secure storage');
      }
    }
  }

  Future<void> removeKey(int index) async {
    var indexStr = index.toString();
    _privateKeyMap.remove(indexStr);
    await _encodePrivateKeyMap();

    _nwcUrlMap.remove(indexStr);
    await _encodeNwcUrlMap();

    // Update currentIndex if it pointed to the removed key
    if (_privateKeyIndex == index) {
      if (_privateKeyMap.isEmpty) {
        _privateKeyIndex = null;
      } else {
        _privateKeyIndex = int.tryParse(_privateKeyMap.keys.first);
      }
      await SecureStorageUtil.writePrivateKeyIndex(_privateKeyIndex);
    }

    notifyListeners();
  }

  String? getNwcUrl(int? index) {
    if (index == null) return null;
    var indexKey = index.toString();
    return _nwcUrlMap[indexKey];
  }

  Future<void> setNwcUrl(int? index, String? url) async {
    if (index == null) return;

    var indexKey = index.toString();
    if (StringUtil.isNotBlank(url)) {
      _nwcUrlMap[indexKey] = url!;
    } else {
      _nwcUrlMap.remove(indexKey);
    }

    await _encodeNwcUrlMap();
    notifyListeners();
  }

  Future<void> _encodeNwcUrlMap() async {
    if (_useSecureStorage) {
      var result = await SecureStorageUtil.writeNwcUrlMap(_nwcUrlMap);
      if (!result) {
        _useSecureStorage = false;
        log('SecureProvider: failed to write NWC to secure storage');
      }
    }
  }
}
