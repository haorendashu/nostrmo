import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/nip02/nip02.dart';
import 'package:nostr_sdk/nip07/nip07_signer.dart';
import 'package:nostr_sdk/nip19/nip19.dart';
import 'package:nostr_sdk/nip46/nostr_remote_signer.dart';
import 'package:nostr_sdk/nip46/nostr_remote_signer_info.dart';
import 'package:nostr_sdk/nip55/android_nostr_signer.dart';
import 'package:nostr_sdk/nip65/nip65.dart';
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
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/base_consts.dart';

import '../consts/client_connected.dart';
import '../main.dart';
import 'data_util.dart';

class RelayProvider extends ChangeNotifier {
  static RelayProvider? _relayProvider;

  List<String> relayAddrs = [];

  Map<String, RelayStatus> relayStatusMap = {};

  List<String> cacheRelayAddrs = [];

  RelayStatus? relayStatusLocal;

  Map<String, RelayStatus> _tempRelayStatusMap = {};

  static RelayProvider getInstance() {
    if (_relayProvider == null) {
      _relayProvider = RelayProvider();
      // _relayProvider!._load();
      var l = sharedPreferences.getStringList(DataKey.CACHE_RELAYS);
      if (l != null) {
        _relayProvider!.cacheRelayAddrs.clear();
        _relayProvider!.cacheRelayAddrs.addAll(l);
      }
    }
    return _relayProvider!;
  }

  void loadRelayAddrs(String? content) {
    var relays = parseRelayAddrs(content);
    if (relays.isEmpty) {
      relays = [
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
    }

    relayAddrs = relays;
  }

  List<String> parseRelayAddrs(String? content) {
    List<String> relays = [];
    if (StringUtil.isBlank(content)) {
      return relays;
    }

    var relayStatuses = NIP02.parseContenToRelays(content!);
    for (var relayStatus in relayStatuses) {
      var addr = relayStatus.addr;
      relays.add(addr);

      var oldRelayStatus = relayStatusMap[addr];
      if (oldRelayStatus != null) {
        oldRelayStatus.readAccess = relayStatus.readAccess;
        oldRelayStatus.writeAccess = relayStatus.writeAccess;
      } else {
        relayStatusMap[addr] = relayStatus;
      }
    }

    return relays;
  }

  RelayStatus? getRelayStatus(String addr) {
    return relayStatusMap[addr];
  }

  String relayNumStr() {
    var normalLength = relayAddrs.length;
    var cacheLength = cacheRelayAddrs.length;

    int connectedNum = 0;
    var it = relayStatusMap.values;
    for (var status in it) {
      if (status.connected == ClientConneccted.CONNECTED) {
        connectedNum++;
      }
    }
    return "$connectedNum / ${normalLength + cacheLength}";
  }

  int total() {
    return relayAddrs.length;
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
      giftWrapProvider.query();
    });

    loadRelayAddrs(contactListProvider.content);
    listProvider.load(_nostr.publicKey,
        [EventKind.BOOKMARKS_LIST, EventKind.EMOJIS_LIST, EventKind.GROUP_LIST],
        targetNostr: _nostr, initQuery: true);
    badgeProvider.reload(targetNostr: _nostr, initQuery: true);

    // add local relay
    if (relayLocalDB != null &&
        settingProvider.relayLocal != OpenStatus.CLOSE) {
      relayStatusLocal = RelayStatus(RelayLocal.URL);
      var relayLocal =
          RelayLocal(RelayLocal.URL, relayStatusLocal!, relayLocalDB!)
            ..relayStatusCallback = onRelayStatusChange;
      _nostr.addRelay(relayLocal, init: true);
    }

    for (var relayAddr in relayAddrs) {
      log("begin to init $relayAddr");
      var custRelay = genRelay(relayAddr);
      try {
        _nostr.addRelay(custRelay, init: true);
      } catch (e) {
        log("relay $relayAddr add to pool error ${e.toString()}");
      }
    }

    for (var relayAddr in cacheRelayAddrs) {
      log("begin to init $relayAddr");
      var custRelay = genRelay(relayAddr, relayType: RelayType.CACHE);
      try {
        _nostr.addRelay(custRelay, init: true, relayType: RelayType.CACHE);
      } catch (e) {
        log("relay $relayAddr add to pool error ${e.toString()}");
      }
    }

    return _nostr;
  }

  void onRelayStatusChange() {
    notifyListeners();
  }

  void addRelay(String relayAddr) {
    if (!relayAddrs.contains(relayAddr)) {
      relayAddrs.add(relayAddr);
      _doAddRelay(relayAddr);
      saveRelay();
    }
  }

  void addCacheRelay(String relayAddr) {
    if (!cacheRelayAddrs.contains(relayAddr)) {
      cacheRelayAddrs.add(relayAddr);
      _doAddRelay(relayAddr, relayType: RelayType.CACHE);
      saveCacheRelay();
      notifyListeners();
    }
  }

  void _doAddRelay(String relayAddr,
      {bool init = false, int relayType = RelayType.NORMAL}) {
    var custRelay = genRelay(relayAddr, relayType: relayType);
    log("begin to init $relayAddr");
    nostr!.addRelay(custRelay,
        autoSubscribe: true, init: init, relayType: relayType);
  }

  void removeRelay(String relayAddr) {
    if (relayAddrs.contains(relayAddr)) {
      relayAddrs.remove(relayAddr);
      relayStatusMap.remove(relayAddr);
      nostr!.removeRelay(relayAddr);

      saveRelay();
    } else if (cacheRelayAddrs.contains(relayAddr)) {
      cacheRelayAddrs.remove(relayAddr);
      relayStatusMap.remove(relayAddr);
      nostr!.removeRelay(relayAddr, relayType: RelayType.CACHE);

      saveCacheRelay();
      notifyListeners();
    }
  }

  void saveRelay() {
    _updateRelayToContactList();

    // save to NIP-65
    var relayStatuses = _getRelayStatuses();
    NIP65.save(nostr!, relayStatuses);
  }

  void saveCacheRelay() {
    sharedPreferences.setStringList(DataKey.CACHE_RELAYS, cacheRelayAddrs);
  }

  void _updateRelayToContactList() {
    var relayStatuses = _getRelayStatuses();
    var relaysContent = NIP02.relaysToContent(relayStatuses);
    contactListProvider.updateRelaysContent(relaysContent);
    notifyListeners();
  }

  List<String> getWritableRelays() {
    List<String> list = [];
    for (var addr in relayAddrs) {
      var relayStatus = relayStatusMap[addr];
      if (relayStatus != null && relayStatus.writeAccess) {
        list.add(addr);
      }
    }
    return list;
  }

  List<RelayStatus> _getRelayStatuses() {
    List<RelayStatus> relayStatuses = [];
    for (var addr in relayAddrs) {
      var relayStatus = relayStatusMap[addr];
      if (relayStatus != null) {
        relayStatuses.add(relayStatus);
      }
    }
    return relayStatuses;
  }

  Relay genRelay(String relayAddr, {int relayType = RelayType.NORMAL}) {
    var relayStatus = relayStatusMap[relayAddr];
    if (relayStatus == null) {
      relayStatus = RelayStatus(relayAddr, relayType: relayType);
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

  void relayUpdateByContactListEvent(Event event) {
    List<String> oldRelays = []..addAll(relayAddrs);
    loadRelayAddrs(event.content);
    _updateRelays(oldRelays);
  }

  void _updateRelays(List<String> oldRelays) {
    List<String> needToRemove = [];
    List<String> needToAdd = [];
    for (var oldRelay in oldRelays) {
      if (!relayAddrs.contains(oldRelay)) {
        // new addrs don't contain old relay, need to remove
        needToRemove.add(oldRelay);
      }
    }
    for (var relayAddr in relayAddrs) {
      if (!oldRelays.contains(relayAddr)) {
        // old addrs don't contain new relay, need to add
        needToAdd.add(relayAddr);
      }
    }

    for (var relayAddr in needToRemove) {
      relayStatusMap.remove(relayAddr);
      nostr!.removeRelay(relayAddr);
    }
    for (var relayAddr in needToAdd) {
      _doAddRelay(relayAddr);
    }
  }

  void clear() {
    // sharedPreferences.remove(DataKey.RELAY_LIST);
    relayStatusMap.clear();
    loadRelayAddrs(null);
    _tempRelayStatusMap.clear();
  }

  List<RelayStatus> tempRelayStatus() {
    List<RelayStatus> list = []..addAll(_tempRelayStatusMap.values);
    return list;
  }

  Relay genTempRelay(String addr) {
    var rs = _tempRelayStatusMap[addr];
    if (rs == null) {
      rs = RelayStatus(addr);
      _tempRelayStatusMap[addr] = rs;
    }

    return _doGenRelay(rs);
  }

  void cleanTempRelays() {
    List<String> needRemoveList = [];
    var now = DateTime.now().millisecondsSinceEpoch;
    for (var entry in _tempRelayStatusMap.entries) {
      var addr = entry.key;
      var status = entry.value;

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
      _tempRelayStatusMap.remove(addr);
      nostr!.removeTempRelay(addr);
    }
  }
}
