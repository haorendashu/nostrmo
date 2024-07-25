import 'package:nostrmo/client/signer/pubkey_only_nostr_signer.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_util.dart';

import 'client_utils/keys.dart';
import 'event.dart';
import 'event_kind.dart';
import 'nip02/cust_contact_list.dart';
import 'relay/relay.dart';
import 'relay/relay_pool.dart';
import 'signer/nostr_signer.dart';

class Nostr {
  late RelayPool _pool;

  NostrSigner nostrSigner;

  String _publicKey;

  Nostr(this.nostrSigner, this._publicKey) {
    _pool = RelayPool(this);
  }

  String get publicKey => _publicKey;

  Future<Event?> sendLike(String id,
      {String? pubkey,
      String? content,
      List<String>? tempRelays,
      List<String>? targetRelays}) async {
    if (pubkey != null) {
      tempRelays ??= [];
      tempRelays.addAll(metadataProvider.getExtralRelays(pubkey, false));
    }

    content ??= "+";

    Event event = Event(
        _publicKey,
        EventKind.REACTION,
        [
          ["e", id]
        ],
        content);
    return await sendEvent(event,
        tempRelays: tempRelays, targetRelays: targetRelays);
  }

  Future<Event?> deleteEvent(String eventId,
      {List<String>? tempRelays, List<String>? targetRelays}) async {
    Event event = Event(
        _publicKey,
        EventKind.EVENT_DELETION,
        [
          ["e", eventId]
        ],
        "delete");
    return await sendEvent(event,
        tempRelays: tempRelays, targetRelays: targetRelays);
  }

  Future<Event?> deleteEvents(List<String> eventIds,
      {List<String>? tempRelays, List<String>? targetRelays}) async {
    List<List<dynamic>> tags = [];
    for (var eventId in eventIds) {
      tags.add(["e", eventId]);
    }

    Event event = Event(_publicKey, EventKind.EVENT_DELETION, tags, "delete");
    return await sendEvent(event,
        tempRelays: tempRelays, targetRelays: targetRelays);
  }

  Future<Event?> sendRepost(String id,
      {String? relayAddr,
      String content = "",
      List<String>? tempRelays,
      List<String>? targetRelays}) async {
    List<dynamic> tag = ["e", id];
    if (StringUtil.isNotBlank(relayAddr)) {
      tag.add(relayAddr);
    }
    Event event = Event(_publicKey, EventKind.REPOST, [tag], content);
    return await sendEvent(event,
        tempRelays: tempRelays, targetRelays: targetRelays);
  }

  Future<Event?> sendContactList(CustContactList contacts, String content,
      {List<String>? tempRelays, List<String>? targetRelays}) async {
    final tags = contacts.toJson();
    final event = Event(_publicKey, EventKind.CONTACT_LIST, tags, content);
    return await sendEvent(event,
        tempRelays: tempRelays, targetRelays: targetRelays);
  }

  Future<Event?> sendEvent(Event event,
      {List<String>? tempRelays, List<String>? targetRelays}) async {
    await signEvent(event);
    if (StringUtil.isBlank(event.sig)) {
      return null;
    }

    var result = _pool.send(
      ["EVENT", event.toJson()],
      tempRelays: tempRelays,
      targetRelays: targetRelays,
    );
    if (result) {
      return event;
    }
    return null;
  }

  void checkEventSign(Event event) {
    if (StringUtil.isBlank(event.sig)) {
      throw StateError("Event is not signed");
    }
  }

  Future<void> signEvent(Event event) async {
    var ne = await nostrSigner.signEvent(event);
    if (ne != null) {
      event.id = ne.id;
      event.sig = ne.sig;
    }
  }

  Event? broadcase(Event event,
      {List<String>? tempRelays, List<String>? targetRelays}) {
    var result = _pool.send(
      ["EVENT", event.toJson()],
      tempRelays: tempRelays,
      targetRelays: targetRelays,
    );
    if (result) {
      return event;
    }
    return null;
  }

  void close() {
    _pool.removeAll();
  }

  void addInitQuery(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    _pool.addInitQuery(filters, onEvent, id: id, onComplete: onComplete);
  }

  String subscribe(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id}) {
    return _pool.subscribe(filters, onEvent, id: id);
  }

  void unsubscribe(String id) {
    _pool.unsubscribe(id);
  }

  String query(
    List<Map<String, dynamic>> filters,
    Function(Event) onEvent, {
    String? id,
    Function? onComplete,
    List<String>? tempRelays,
    bool onlyTempRelays = false,
    bool queryLocal = true,
    bool sendAfterAuth = false,
    bool? runBeforeConnected,
  }) {
    return _pool.query(
      filters,
      onEvent,
      id: id,
      onComplete: onComplete,
      tempRelays: tempRelays,
      onlyTempRelays: onlyTempRelays,
      queryLocal: queryLocal,
      sendAfterAuth: sendAfterAuth,
      runBeforeConnected: runBeforeConnected,
    );
  }

  String queryByFilters(Map<String, List<Map<String, dynamic>>> filtersMap,
      Function(Event) onEvent,
      {String? id, Function? onComplete}) {
    return _pool.queryByFilters(filtersMap, onEvent,
        id: id, onComplete: onComplete);
  }

  Future<bool> addRelay(
    Relay relay, {
    bool autoSubscribe = false,
    bool init = false,
  }) async {
    return await _pool.add(relay, autoSubscribe: autoSubscribe, init: init);
  }

  void removeRelay(String url) {
    _pool.remove(url);
  }

  List<Relay> activeRelays() {
    return _pool.activeRelays();
  }

  Relay? getRelay(String url) {
    return _pool.getRelay(url);
  }

  Relay? getTempRelay(String url) {
    return _pool.getTempRelay(url);
  }

  void reconnect() {
    print("nostr reconnect");
    _pool.reconnect();
  }

  List<String> getExtralReadableRelays(
      List<String> extralRelays, int maxRelayNum) {
    return _pool.getExtralReadableRelays(extralRelays, maxRelayNum);
  }

  void removeTempRelay(String addr) {
    _pool.removeTempRelay(addr);
  }

  bool readable() {
    return _pool.readable();
  }

  bool writable() {
    return _pool.writable();
  }

  bool isReadOnly() {
    return nostrSigner is PubkeyOnlyNostrSigner;
  }
}
