import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_util.dart';

import 'client_utils/keys.dart';
import 'event.dart';
import 'event_kind.dart';
import 'nip02/cust_contact_list.dart';
import 'relay/relay.dart';
import 'relay/relay_pool.dart';

class Nostr {
  String? _privateKey;

  late String _publicKey;

  late RelayPool _pool;

  Nostr({
    String? privateKey,
    String? publicKey,
  }) {
    if (StringUtil.isNotBlank(privateKey)) {
      _privateKey = privateKey!;
      _publicKey = getPublicKey(privateKey);
    } else {
      assert(publicKey != null);

      _privateKey = privateKey;
      _publicKey = publicKey!;
    }
    _pool = RelayPool(this);
  }

  String? get privateKey => _privateKey;

  String get publicKey => _publicKey;

  Event? sendLike(String id, {String? pubkey, String? content}) {
    List<String> tempRelays = [];
    if (pubkey != null) {
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
    return sendEvent(event, tempRelays: tempRelays);
  }

  Event? deleteEvent(String eventId) {
    Event event = Event(
        _publicKey,
        EventKind.EVENT_DELETION,
        [
          ["e", eventId]
        ],
        "delete");
    return sendEvent(event);
  }

  Event? deleteEvents(List<String> eventIds) {
    List<List<dynamic>> tags = [];
    for (var eventId in eventIds) {
      tags.add(["e", eventId]);
    }

    Event event = Event(_publicKey, EventKind.EVENT_DELETION, tags, "delete");
    return sendEvent(event);
  }

  Event? sendRepost(String id, {String? relayAddr, String content = ""}) {
    List<dynamic> tag = ["e", id];
    if (StringUtil.isNotBlank(relayAddr)) {
      tag.add(relayAddr);
    }
    Event event = Event(_publicKey, EventKind.REPOST, [tag], content);
    return sendEvent(event);
  }

  Event? sendTextNote(String text, [List<dynamic> tags = const []]) {
    Event event = Event(_publicKey, EventKind.TEXT_NOTE, tags, text);
    return sendEvent(event);
  }

  Event? recommendServer(String url) {
    if (!url.contains(RegExp(
        r'^(wss?:\/\/)([0-9]{1,3}(?:\.[0-9]{1,3}){3}|[^:]+):?([0-9]{1,5})?$'))) {
      throw ArgumentError.value(url, 'url', 'Not a valid relay URL');
    }
    final event = Event(_publicKey, EventKind.RECOMMEND_SERVER, [], url);
    return sendEvent(event);
  }

  Event? sendContactList(CustContactList contacts, String content) {
    final tags = contacts.toJson();
    final event = Event(_publicKey, EventKind.CONTACT_LIST, tags, content);
    return sendEvent(event);
  }

  Event? sendEvent(Event event, {List<String>? tempRelays}) {
    if (StringUtil.isBlank(_privateKey)) {
      // TODO to show Notice
      throw StateError("Private key is missing. Message can't be signed.");
    }
    signEvent(event);
    var result = _pool.send(["EVENT", event.toJson()], tempRelays: tempRelays);
    if (result) {
      return event;
    }
    return null;
  }

  void signEvent(Event event) {
    event.sign(_privateKey!);
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

  String query(List<Map<String, dynamic>> filters, Function(Event) onEvent,
      {String? id,
      Function? onComplete,
      List<String>? tempRelays,
      bool onlyTempRelays = true}) {
    return _pool.query(filters, onEvent,
        id: id,
        onComplete: onComplete,
        tempRelays: tempRelays,
        onlyTempRelays: onlyTempRelays);
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
}
