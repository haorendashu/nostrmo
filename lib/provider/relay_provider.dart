import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip07/nip07_signer.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/client/nip46/nostr_remote_signer.dart';
import 'package:nostrmo/client/nip46/nostr_remote_signer_info.dart';
import 'package:nostrmo/client/nip55/android_nostr_signer.dart';
import 'package:nostrmo/client/relay_local/relay_local.dart';
import 'package:nostrmo/client/signer/pubkey_only_nostr_signer.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/consts/relay_mode.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:nostrmo/util/string_util.dart';

import '../client/event.dart';
import '../client/event_kind.dart' as kind;
import '../client/nostr.dart';
import '../client/relay/relay.dart';
import '../client/relay/relay_base.dart';
import '../client/relay/relay_isolate.dart';
import '../client/signer/local_nostr_signer.dart';
import '../client/signer/nostr_signer.dart';
import '../consts/client_connected.dart';
import '../data/relay_status.dart';
import '../main.dart';
import 'data_util.dart';

class RelayProvider extends ChangeNotifier {
  static RelayProvider? _relayProvider;

  List<String> relayAddrs = [];

  Map<String, RelayStatus> relayStatusMap = {};

  RelayStatus? relayStatusLocal;

  Map<String, RelayStatus> _tempRelayStatusMap = {};

  static RelayProvider getInstance() {
    if (_relayProvider == null) {
      _relayProvider = RelayProvider();
      // _relayProvider!._load();
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

    var jsonObj = jsonDecode(content!);
    Map<dynamic, dynamic> jsonMap =
        jsonObj.map((key, value) => MapEntry(key, true));

    for (var entry in jsonMap.entries) {
      var key = entry.key.toString();
      relays.add(key);

      var value = jsonObj[key];

      var readAcccess = value["read"] == true;
      var writeAcccess = value["write"] == true;

      var relayStatus = relayStatusMap[key];
      if (relayStatus == null) {
        relayStatus = RelayStatus(key);
        relayStatus.readAccess = readAcccess;
        relayStatus.writeAccess = writeAcccess;
        relayStatusMap[key] = relayStatus;
      }
    }

    return relays;
  }

  RelayStatus? getRelayStatus(String addr) {
    return relayStatusMap[addr];
  }

  String relayNumStr() {
    var total = relayAddrs.length;

    int connectedNum = 0;
    var it = relayStatusMap.values;
    for (var status in it) {
      if (status.connected == ClientConneccted.CONNECTED) {
        connectedNum++;
      }
    }
    return "$connectedNum / $total";
  }

  int total() {
    return relayAddrs.length;
  }

  Future<Nostr?> genNostrWithKey(String key) async {
    NostrSigner? nostrSigner;
    if (Nip19.isPubkey(key)) {
      nostrSigner = PubkeyOnlyNostrSigner(Nip19.decode(key));
    } else if (AndroidNostrSigner.isAndroidNostrSignerKey(key)) {
      nostrSigner = AndroidNostrSigner();
    } else if (NIP07Signer.isWebNostrSignerKey(key)) {
      nostrSigner = NIP07Signer();
    } else if (NostrRemoteSignerInfo.isBunkerUrl(key)) {
      var info = NostrRemoteSignerInfo.parseBunkerUrl(key);
      if (info == null) {
        return null;
      }
      nostrSigner = NostrRemoteSigner(info);
      await (nostrSigner as NostrRemoteSigner).connect();
    } else {
      nostrSigner = LocalNostrSigner(key);
    }
    return await genNostr(nostrSigner);
  }

  Future<Nostr?> genNostr(NostrSigner signer) async {
    var pubkey = await signer.getPublicKey();
    if (pubkey == null) {
      return null;
    }

    var _nostr = Nostr(signer, pubkey);
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
        [kind.EventKind.BOOKMARKS_LIST, kind.EventKind.EMOJIS_LIST],
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

  void _doAddRelay(String relayAddr, {bool init = false}) {
    var custRelay = genRelay(relayAddr);
    log("begin to init $relayAddr");
    nostr!.addRelay(custRelay, autoSubscribe: true, init: init);
  }

  void removeRelay(String relayAddr) {
    if (relayAddrs.contains(relayAddr)) {
      relayAddrs.remove(relayAddr);
      relayStatusMap.remove(relayAddr);
      nostr!.removeRelay(relayAddr);

      saveRelay();
    }
  }

  // bool containRelay(String relayAddr) {
  //   return relayAddrs.contains(relayAddr);
  // }

  void saveRelay() {
    _updateRelayToContactList();

    // save to NIP-65
    List tags = [];
    for (var addr in relayAddrs) {
      var readAccess = true;
      var writeAccess = true;

      var relayStatus = relayStatusMap[addr];
      if (relayStatus != null) {
        readAccess = relayStatus.readAccess;
        writeAccess = relayStatus.writeAccess;
      }

      List<String> tag = ["r", addr];
      if (readAccess != true || writeAccess != true) {
        if (readAccess) {
          tag.add("read");
        }
        if (writeAccess) {
          tag.add("write");
        }
      }
      tags.add(tag);
    }

    var e =
        Event(nostr!.publicKey, kind.EventKind.RELAY_LIST_METADATA, tags, "");
    nostr!.sendEvent(e);
  }

  void _updateRelayToContactList() {
    Map<String, dynamic> relaysContentMap = {};
    for (var addr in relayAddrs) {
      var readAccess = true;
      var writeAccess = true;

      var relayStatus = relayStatusMap[addr];
      if (relayStatus != null) {
        readAccess = relayStatus.readAccess;
        writeAccess = relayStatus.writeAccess;
      }

      relaysContentMap[addr] = {
        "read": readAccess,
        "write": writeAccess,
      };
    }
    var relaysContent = jsonEncode(relaysContentMap);
    contactListProvider.updateRelaysContent(relaysContent);

    notifyListeners();
  }

  Relay genRelay(String relayAddr) {
    var relayStatus = relayStatusMap[relayAddr];
    if (relayStatus == null) {
      relayStatus = RelayStatus(relayAddr);
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
                  1000 * 60 * 10))) {
        needRemoveList.add(addr);
      }
    }

    for (var addr in needRemoveList) {
      _tempRelayStatusMap.remove(addr);
      nostr!.removeTempRelay(addr);
    }
  }
}
