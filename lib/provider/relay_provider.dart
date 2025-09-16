import 'dart:convert';
import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:nesigner_adapter/nesigner.dart';
import 'package:nesigner_adapter/nesigner_util.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/nip02/nip02.dart';
import 'package:nostr_sdk/nip07/nip07_signer.dart';
import 'package:nostr_sdk/nip19/nip19.dart';
import 'package:nostr_sdk/nip46/nostr_remote_signer.dart';
import 'package:nostr_sdk/nip46/nostr_remote_signer_info.dart';
import 'package:nostr_sdk/nip51/indexer_relay_list.dart';
import 'package:nostr_sdk/nip55/android_nostr_signer.dart';
import 'package:nostr_sdk/nip65/nip65.dart';
import 'package:nostr_sdk/nip65/relay_list_metadata.dart';
import 'package:nostr_sdk/nostr.dart';
import 'package:nostr_sdk/relay/relay.dart';
import 'package:nostr_sdk/relay/relay_base.dart';
import 'package:nostr_sdk/relay/relay_isolate.dart';
import 'package:nostr_sdk/relay/relay_mode.dart';
import 'package:nostr_sdk/relay/relay_status.dart';
import 'package:nostr_sdk/relay/relay_type.dart';
import 'package:nostr_sdk/relay_local/relay_local.dart';
import 'package:nostr_sdk/signer/local_nostr_signer.dart';
import 'package:nostr_sdk/signer/nostr_signer.dart';
import 'package:nostr_sdk/signer/pubkey_only_nostr_signer.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/relay_addr_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/base_consts.dart';

import '../consts/client_connected.dart';
import '../main.dart';
import 'data_util.dart';

class RelayProvider extends ChangeNotifier {
  static RelayProvider? _relayProvider;

  static List<String> DEFAULT_RELAYS = [
    "wss://nos.lol",
    "wss://nostr.wine",
    "wss://atlas.nostr.land",
    "wss://relay.damus.io",
    "wss://nostr-relay.app",
    "wss://nostr.oxtr.dev",
    "wss://relayable.org",
    "wss://relay.primal.net",
    "wss://relay.nostr.bg",
    "wss://relay.nostr.band",
    "wss://yabu.me",
    "wss://nostr.mom"
  ];

  RelayListMetadata? _defaultRelayListMetadata;

  RelayListMetadata? _relayListMetadata;

  IndexerRelayList? indexerRelayList;

  RelayStatus? relayStatusLocal;

  RelayListMetadata get relayListMetadata {
    if (_relayListMetadata != null) {
      return _relayListMetadata!;
    }
    _defaultRelayListMetadata ??=
        RelayListMetadata.fromRelayList(DEFAULT_RELAYS);
    return _defaultRelayListMetadata!;
  }

  Map<int, Map<String, RelayStatus>> relayStatusMapMap = {};

  Map<String, RelayStatus> getRelayStatusMap(int relayType) {
    var relayStatusMap = relayStatusMapMap[relayType];
    if (relayStatusMap == null) {
      relayStatusMap = {};
      relayStatusMapMap[relayType] = relayStatusMap;
    }
    return relayStatusMap;
  }

  Map<String, RelayStatus> get normalRelayStatusMap =>
      getRelayStatusMap(RelayType.NORMAL);

  Map<String, RelayStatus> get cacheRelayStatusMap =>
      getRelayStatusMap(RelayType.CACHE);

  Map<String, RelayStatus> get tempRelayStatusMap =>
      getRelayStatusMap(RelayType.TEMP);

  Map<String, RelayStatus> get indexRelayStatusMap =>
      getRelayStatusMap(RelayType.INDEX);

  static RelayProvider getInstance() {
    if (_relayProvider == null) {
      _relayProvider = RelayProvider();
      _relayProvider!.relayStatusMapMap.clear();
    }
    return _relayProvider!;
  }

  RelayStatus? getNormalOrCacheRelayStatus(String addr) {
    var rs = _doGetRelayStatus(addr, RelayType.NORMAL);
    if (rs != null) {
      return rs;
    }

    return _doGetRelayStatus(addr, RelayType.CACHE);
  }

  RelayStatus? _doGetRelayStatus(String addr, int relayType) {
    var relayStatusMap = relayStatusMapMap[relayType];
    if (relayStatusMap != null) {
      return relayStatusMap[addr];
    }

    return null;
  }

  String relayNumStr() {
    var normalRelayStatuses = _getRelayStatuses(relayType: RelayType.NORMAL);
    var indexRelayStatuses = _getRelayStatuses(relayType: RelayType.INDEX);
    var cacheRelayStatuses = _getRelayStatuses(relayType: RelayType.CACHE);
    var normalLength = normalRelayStatuses.length;
    var indexLength = indexRelayStatuses.length;
    var cacheLength = cacheRelayStatuses.length;

    int connectedNum = 0;
    for (var status in normalRelayStatuses) {
      if (status.connected == ClientConneccted.CONNECTED) {
        connectedNum++;
      }
    }
    for (var status in indexRelayStatuses) {
      if (status.connected == ClientConneccted.CONNECTED) {
        connectedNum++;
      }
    }
    for (var status in cacheRelayStatuses) {
      if (status.connected == ClientConneccted.CONNECTED) {
        connectedNum++;
      }
    }
    return "$connectedNum / ${normalLength + cacheLength + indexLength}";
  }

  int total() {
    var normalRelayStatuses = _getRelayStatuses(relayType: RelayType.NORMAL);
    var cacheRelayStatuses = _getRelayStatuses(relayType: RelayType.CACHE);
    var normalLength = normalRelayStatuses.length;
    var cacheLength = cacheRelayStatuses.length;

    return normalLength + cacheLength;
  }

  Future<Nostr?> genNostrWithKey(String key) async {
    NostrSigner? nostrSigner;
    if (Nip19.isPubkey(key)) {
      nostrSigner = PubkeyOnlyNostrSigner(Nip19.decode(key));
    } else if (AndroidNostrSigner.isAndroidNostrSignerKey(key)) {
      var pubkey = AndroidNostrSigner.getPubkeyFromKey(key);
      var package = AndroidNostrSigner.getPackageFromKey(key);
      nostrSigner = AndroidNostrSigner(pubkey: pubkey, package: package);
    } else if (NIP07Signer.isWebNostrSignerKey(key)) {
      var pubkey = NIP07Signer.getPubkey(key);
      nostrSigner = NIP07Signer(pubkey: pubkey);
    } else if (NostrRemoteSignerInfo.isBunkerUrl(key)) {
      var info = NostrRemoteSignerInfo.parseBunkerUrl(key);
      if (info == null) {
        return null;
      }

      bool hasConnected = false;
      if (StringUtil.isNotBlank(info.userPubkey)) {
        hasConnected = true;
      }

      nostrSigner = NostrRemoteSigner(
          settingProvider.relayMode != null
              ? settingProvider.relayMode!
              : RelayMode.FAST_MODE,
          info);
      await (nostrSigner as NostrRemoteSigner)
          .connect(sendConnectRequest: !hasConnected);

      if (StringUtil.isBlank(info.userPubkey)) {
        await nostrSigner.pullPubkey();
      }

      if (await nostrSigner.getPublicKey() == null) {
        return null;
      }
    } else if (Nesigner.isNesignerKey(key)) {
      var pinCode = Nesigner.getPinCodeFromKey(key);
      var pubkey = Nesigner.getPubkeyFromKey(key);
      nostrSigner = Nesigner(pinCode, pubkey: pubkey);
      try {
        if (!(await (nostrSigner as Nesigner).start())) {
          return null;
        }
      } catch (e) {
        return null;
      }
    } else {
      try {
        nostrSigner = LocalNostrSigner(key);
      } catch (e) {}
    }

    if (nostrSigner == null) {
      return null;
    }

    return await genNostr(nostrSigner);
  }

  Future<Nostr?> genNostr(NostrSigner signer) async {
    var pubkey = await signer.getPublicKey();
    if (pubkey == null) {
      return null;
    }

    loadRelayListMetadata(pubkey);
    await loadIndexerRelayList(pubkey, signer);
    notifyListeners();

    var _nostr = Nostr(signer, pubkey, [filterProvider], genTempRelay,
        onNotice: noticeProvider.onNotice);
    log("nostr init over");

    // add initQuery
    var dmInitFuture = dmProvider.initDMSessions(_nostr.publicKey);
    var giftWrapFuture = giftWrapProvider.init();
    contactListProvider.reload(targetNostr: _nostr);
    contactListProvider.query(targetNostr: _nostr);
    followEventProvider.doQuery(targetNostr: _nostr, initQuery: true);
    mentionMeProvider.doQuery(targetNostr: _nostr, initQuery: true);
    // don't query after init, due to query dm need login to relay so the first query change to call by timer
    // dmInitFuture.then((_) {
    //   dmProvider.query(targetNostr: _nostr, initQuery: true);
    // });
    giftWrapFuture.then((_) {
      giftWrapProvider.query(initQuery: true);
    });

    listProvider.load(
        _nostr.publicKey,
        [
          EventKind.BOOKMARKS_LIST,
          EventKind.EMOJIS_LIST,
          EventKind.GROUP_LIST,
          EventKind.INDEXER_RELAY_LIST,
          EventKind
              .RELAY_LIST_METADATA, // load relay list metadata direct from relays.
        ],
        targetNostr: _nostr,
        initQuery: true);
    badgeProvider.reload(targetNostr: _nostr, initQuery: true);

    ///
    /// local relay
    ///
    if (localRelayDB != null &&
        settingProvider.relayLocal != OpenStatus.CLOSE) {
      relayStatusLocal =
          RelayStatus(RelayLocal.URL, relayType: RelayType.LOCAL);
      var relayLocal =
          RelayLocal(RelayLocal.URL, relayStatusLocal!, localRelayDB!)
            ..relayStatusCallback = onRelayStatusChange;
      _doAddRelayToNostr(_nostr, relayLocal, RelayType.LOCAL);
    }

    ///
    /// Normal Relays
    ///
    handleNormalRelays(_nostr);

    ///
    /// Cache Relays
    ///
    var cacheRelayAddrs = sharedPreferences.getStringList(DataKey.CACHE_RELAYS);
    if (cacheRelayAddrs != null) {
      for (var relayAddr in cacheRelayAddrs) {
        log("begin to init cacheRelay $relayAddr");
        var relay = genRelay(relayAddr, relayType: RelayType.CACHE);
        _doAddRelayToNostr(_nostr, relay, RelayType.CACHE);
      }
    }

    ///
    /// Index Relays
    ///
    handleIndexRelays(_nostr);

    return _nostr;
  }

  void handleNormalRelays(Nostr _nostr) {
    var relayRWEntrys = relayListMetadata.relayRWMap.entries;
    for (var relayRWEntry in relayRWEntrys) {
      var relayAddr = relayRWEntry.key;
      var rwValue = relayRWEntry.value;
      bool writeAccess =
          rwValue == RelayRW.READ_WRITE || rwValue == RelayRW.WRITE
              ? true
              : false;
      bool readAccess = rwValue == RelayRW.READ_WRITE || rwValue == RelayRW.READ
          ? true
          : false;
      log("begin to init normal $relayAddr");
      var relay = genRelay(
        relayAddr,
        writeAccess: writeAccess,
        readAccess: readAccess,
      );
      _doAddRelayToNostr(_nostr, relay, RelayType.NORMAL);
    }
  }

  void handleIndexRelays(Nostr _nostr) {
    if (indexerRelayList != null) {
      var relayAddrs = indexerRelayList!.relays;
      for (var relayAddr in relayAddrs) {
        log("begin to init indexerRelay $relayAddr");
        var relay = genRelay(relayAddr, relayType: RelayType.INDEX);
        _doAddRelayToNostr(_nostr, relay, RelayType.INDEX);
      }
    }
  }

  void _doAddRelayToNostr(Nostr nostr, Relay relay, int relayType,
      {bool autoSubscribe = false}) {
    try {
      nostr.addRelay(relay,
          init: true, relayType: relayType, autoSubscribe: autoSubscribe);
    } catch (e) {
      log("relay ${relay.url} add to pool error ${e.toString()}");
    }
  }

  void onRelayStatusChange() {
    notifyListeners();
  }

  void saveRelay(int relayType) {
    if (relayType == RelayType.NORMAL) {
      saveNormalRelay();
    } else if (relayType == RelayType.CACHE) {
      saveCacheRelay();
    } else if (relayType == RelayType.INDEX) {
      saveIndexRelay();
    }
  }

  void addRelay(String relayAddr, {int relayType = RelayType.NORMAL}) {
    relayAddr = RelayAddrUtil.handle(relayAddr);
    var relayStatusMap = relayStatusMapMap[relayType];
    if (relayStatusMap == null) {
      relayStatusMap = {};
      relayStatusMapMap[relayType] = relayStatusMap;
    }
    var relayStatus = relayStatusMap[relayAddr];
    if (relayStatus != null) {
      return;
    }

    _doGenAndAddRelay(relayAddr, relayType: relayType);

    saveRelay(relayType);
    notifyListeners();
  }

  void _doGenAndAddRelay(
    String relayAddr, {
    bool init = false,
    int relayType = RelayType.NORMAL,
    bool writeAccess = true,
    bool readAccess = true,
  }) {
    var relay = genRelay(
      relayAddr,
      relayType: relayType,
      writeAccess: writeAccess,
      readAccess: readAccess,
    );
    log("begin to init $relayAddr");
    _doAddRelayToNostr(nostr!, relay, relayType);
  }

  void removeRelay(String relayAddr, int relayType, {bool autoSave = true}) {
    relayAddr = RelayAddrUtil.handle(relayAddr);
    var relayStatusMap = relayStatusMapMap[relayType];
    if (relayStatusMap == null) {
      return;
    }
    relayStatusMap.remove(relayAddr);
    nostr!.removeRelay(relayAddr);

    if (autoSave) {
      saveRelay(relayType);
    }
  }

  Future<void> saveNormalRelay() async {
    _updateRelayToContactList();

    // save to NIP-65
    var relayStatuses = _getRelayStatuses();
    var event = NIP65.save(nostr!, relayStatuses);

    // TODO save info to local and memery
  }

  void saveCacheRelay() {
    var relayStatuses = _getRelayStatuses(relayType: RelayType.CACHE);
    List<String> list = relayStatuses.map((e) => e.addr).toList();
    sharedPreferences.setStringList(DataKey.CACHE_RELAYS, list);
  }

  Future<void> saveIndexRelay() async {
    var relayStatuses = _getRelayStatuses(relayType: RelayType.INDEX);
    List<String> list = relayStatuses.map((e) => e.addr).toList();
    var _indexerRelayList = IndexerRelayList();
    _indexerRelayList.relays = list;
    var event = await _indexerRelayList.toEvent(nostr!);
    if (event != null) {
      nostr!.sendEvent(event);
    }

    // TODO save info to local and memery
  }

  void _updateRelayToContactList() {
    var relayStatuses = _getRelayStatuses();
    var relaysContent = NIP02.relaysToContent(relayStatuses);
    contactListProvider.updateRelaysContent(relaysContent);
    notifyListeners();
  }

  List<String> getReadableRelays() {
    return _getAbleRelays(false);
  }

  List<String> getWritableRelays() {
    return _getAbleRelays(true);
  }

  List<String> _getAbleRelays(bool isWriteAble) {
    var normalRelayStatusMap = getRelayStatusMap(RelayType.NORMAL);
    var relayStatuses = normalRelayStatusMap.values;
    List<String> list = [];
    for (var relayStatus in relayStatuses) {
      if (isWriteAble) {
        if (relayStatus.writeAccess) {
          list.add(relayStatus.addr);
        }
      } else {
        if (relayStatus.readAccess) {
          list.add(relayStatus.addr);
        }
      }
    }
    return list;
  }

  List<RelayStatus> _getRelayStatuses({int relayType = RelayType.NORMAL}) {
    var normalRelayStatusMap = getRelayStatusMap(relayType);
    return normalRelayStatusMap.values.toList();
  }

  Relay genRelay(
    String relayAddr, {
    int relayType = RelayType.NORMAL,
    bool writeAccess = true,
    bool readAccess = true,
  }) {
    var relayStatusMap = getRelayStatusMap(relayType);
    var relayStatus = relayStatusMap[relayAddr];
    if (relayStatus == null) {
      relayStatus = RelayStatus(
        relayAddr,
        relayType: relayType,
        writeAccess: writeAccess,
        readAccess: readAccess,
      );
      relayStatusMap[relayAddr] = relayStatus;
    }

    return _doGenRelay(relayStatus);
  }

  Relay _doGenRelay(RelayStatus relayStatus) {
    var relayAddr = relayStatus.addr;

    if (PlatformUtil.isWeb()) {
      // dart:isolate is not supported on dart4web
      return RelayBase(
        relayAddr,
        relayStatus,
      )..relayStatusCallback = onRelayStatusChange;
    } else {
      if (settingProvider.relayMode == RelayMode.BASE_MODE) {
        return RelayBase(
          relayAddr,
          relayStatus,
        )..relayStatusCallback = onRelayStatusChange;
      } else {
        return RelayIsolate(
          relayAddr,
          relayStatus,
          eventSignCheck: settingProvider.eventSignCheck == OpenStatus.OPEN,
          relayNetwork: settingProvider.network,
        )..relayStatusCallback = onRelayStatusChange;
      }
    }
  }

  void clear() {
    relayStatusMapMap.clear();
    _relayListMetadata = null;
    indexerRelayList = null;
  }

  List<RelayStatus> getNormalRelayStatus() {
    return _getRelayStatuses(relayType: RelayType.NORMAL);
  }

  List<RelayStatus> getTempRelayStatus() {
    return _getRelayStatuses(relayType: RelayType.TEMP);
  }

  List<RelayStatus> getIndexRelayStatus() {
    return _getRelayStatuses(relayType: RelayType.INDEX);
  }

  List<RelayStatus> getCacheRelayStatus() {
    return _getRelayStatuses(relayType: RelayType.CACHE);
  }

  /// This method is used for nostr gen relay and handle relayStatus.
  Relay genTempRelay(String relayAddr) {
    relayAddr = RelayAddrUtil.handle(relayAddr);
    var relayStatusMap = relayStatusMapMap[RelayType.TEMP];
    if (relayStatusMap == null) {
      relayStatusMap = {};
      relayStatusMapMap[RelayType.TEMP] = relayStatusMap;
    }

    var rs = relayStatusMap[relayAddr];
    if (rs == null) {
      rs = RelayStatus(relayAddr, relayType: RelayType.TEMP);
      relayStatusMap[relayAddr] = rs;
    }

    return _doGenRelay(rs);
  }

  void cleanTempRelays() {
    List<String> needRemoveList = [];
    var now = DateTime.now().millisecondsSinceEpoch;
    var _tempRelayStatus = getTempRelayStatus();
    for (var status in _tempRelayStatus) {
      var addr = status.addr;

      if (now - status.connectTime.millisecondsSinceEpoch > 1000 * 60 * 10 &&
          (status.lastNoteTime == null ||
              ((now - status.lastNoteTime!.millisecondsSinceEpoch) >
                  1000 * 60 * 10)) &&
          (status.lastQueryTime == null ||
              ((now - status.lastQueryTime!.millisecondsSinceEpoch) >
                  1000 * 60 * 10))) {
        // init time over 10 min
        // last note time over 10 min
        // last query time over 10 min
        needRemoveList.add(addr);
      }
    }

    for (var addr in needRemoveList) {
      removeRelay(addr, RelayType.TEMP, autoSave: false);
    }

    if (needRemoveList.isNotEmpty) {
      notifyListeners();
    }
  }

  Future<void> onEvent(Event event) async {
    if (event.pubkey != nostr!.publicKey) {
      return;
    }

    if (event.kind == EventKind.RELAY_LIST_METADATA) {
      if (event.createdAt > relayListMetadata.createdAt) {
        var md = RelayListMetadata.fromEvent(event);
        _relayListMetadata = md;
        // handle relays change
        handleNewNormalRelayList();
      } else {
        return;
      }
    } else if (event.kind == EventKind.INDEXER_RELAY_LIST) {
      if (indexerRelayList == null ||
          event.createdAt > indexerRelayList!.createdAt) {
        indexerRelayList =
            await IndexerRelayList.parse(event, nostr!.nostrSigner);
        // handle relay change
        handleNewIndexRelays();
      } else {
        return;
      }
    }

    var key = DataKey.getEventKey(event.pubkey, event.kind);
    var jsonStr = jsonEncode(event.toJson());
    await sharedPreferences.setString(key, jsonStr);
  }

  void handleNewNormalRelayList() {
    var _relayListMetadata = relayListMetadata;
    var _normalRelayStatusMap = normalRelayStatusMap;

    Map<String, int> newRelayRWMap = {}..addAll(_relayListMetadata.relayRWMap);
    var currentRelayStatusEntries = _normalRelayStatusMap.entries;
    List<String> needRemoveList = [];
    for (var entry in currentRelayStatusEntries) {
      var relayAddr = entry.key;
      var relayStatus = entry.value;

      var relayRW = newRelayRWMap.remove(relayAddr);
      if (relayRW != null) {
        // relayRW exist! check Read and Write
        if (relayRW == RelayRW.READ_WRITE) {
          relayStatus.readAccess = true;
          relayStatus.writeAccess = true;
        } else if (relayRW == RelayRW.READ) {
          relayStatus.readAccess = true;
          relayStatus.writeAccess = false;
        } else if (relayRW == RelayRW.WRITE) {
          relayStatus.readAccess = false;
          relayStatus.writeAccess = true;
        }
      } else {
        // relayRW not exist. need to remove.
        needRemoveList.add(relayAddr);
      }
    }

    // need to add
    for (var entry in newRelayRWMap.entries) {
      var rw = entry.value;
      bool writeAccess = rw == RelayRW.READ_WRITE || rw == RelayRW.WRITE;
      bool readAccess = rw == RelayRW.READ_WRITE || rw == RelayRW.READ;

      _doGenAndAddRelay(
        entry.key,
        writeAccess: writeAccess,
        readAccess: readAccess,
      );
    }

    for (var addr in needRemoveList) {
      removeRelay(addr, RelayType.NORMAL, autoSave: false);
    }
  }

  void handleNewIndexRelays() {
    if (indexerRelayList != null) {
      var newRelayAddrs = indexerRelayList!.relays;
      Map<String, int> newRelayMap = {};
      for (var relayAddr in newRelayAddrs) {
        newRelayMap[relayAddr] = 1;
      }

      List<String> needRemoveList = [];
      var indexRelayStatusList = getIndexRelayStatus();
      for (var relayStatus in indexRelayStatusList) {
        var isExist = newRelayMap.remove(relayStatus.addr);
        if (isExist != null) {
          // new and old both exist;
        } else {
          // new not exist, old exist. need to remove.
          needRemoveList.add(relayStatus.addr);
        }
      }

      // need to add
      for (var entry in newRelayMap.entries) {
        var relayAddr = entry.key;

        _doGenAndAddRelay(
          relayAddr,
          relayType: RelayType.INDEX,
        );
      }

      for (var addr in needRemoveList) {
        removeRelay(addr, RelayType.INDEX, autoSave: false);
      }
    }
  }

  void loadRelayListMetadata(String pubkey) {
    var key = DataKey.getEventKey(pubkey, EventKind.RELAY_LIST_METADATA);
    var jsonStr = sharedPreferences.getString(key);
    if (StringUtil.isNotBlank(jsonStr)) {
      var jsonObj = jsonDecode(jsonStr!);
      try {
        var event = Event.fromJson(jsonObj);
        var md = RelayListMetadata.fromEvent(event);
        _relayListMetadata = md;
      } catch (e) {
        print("loadRelayListMetadata error: $e");
      }
    }
  }

  Future<void> loadIndexerRelayList(
      String pubkey, NostrSigner nostrSigner) async {
    var key = DataKey.getEventKey(pubkey, EventKind.INDEXER_RELAY_LIST);
    var jsonStr = sharedPreferences.getString(key);
    if (StringUtil.isNotBlank(jsonStr)) {
      var jsonObj = jsonDecode(jsonStr!);
      try {
        var event = Event.fromJson(jsonObj);
        indexerRelayList = await IndexerRelayList.parse(event, nostrSigner);
      } catch (e) {
        print("loadIndexerRelayList error: $e");
      }
    }
  }
}
