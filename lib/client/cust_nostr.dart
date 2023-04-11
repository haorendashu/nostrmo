import 'dart:convert';

import 'package:nostr_dart/nostr_dart.dart';

import 'event_kind.dart' as kind;
import 'cust_contact_list.dart';
import 'cust_relay_pool.dart';

class CustNostr {
  String _privateKey;
  String _publicKey = '';
  final int powDifficulty;
  late CustRelayPool pool;

  CustNostr(
      {String privateKey = '',
      this.powDifficulty = 0,
      bool eventVerification = false})
      : _privateKey = privateKey {
    _publicKey = privateKey.isNotEmpty ? getPublicKey(privateKey) : '';
    pool = CustRelayPool(eventVerification: eventVerification);
  }

  set privateKey(String key) {
    if (!keyIsValid(key)) {
      throw ArgumentError.value(key, 'key', 'Invalid key');
    } else {
      _publicKey = getPublicKey(key);
      _privateKey = key;
    }
  }

  String get privateKey => _privateKey;

  String get publicKey => _publicKey;

  Event sendLike(String id) {
    Event event = Event(
        _publicKey,
        kind.EventKind.REACTION,
        [
          ["e", id]
        ],
        "+");
    return sendEvent(event);
  }

  Event deleteEvent(String eventId) {
    Event event = Event(
        _publicKey,
        kind.EventKind.EVENT_DELETION,
        [
          ["e", eventId]
        ],
        "delete");
    return sendEvent(event);
  }

  Event deleteEvents(List<String> eventIds) {
    List<List<dynamic>> tags = [];
    for (var eventId in eventIds) {
      tags.add(["e", eventId]);
    }

    Event event =
        Event(_publicKey, kind.EventKind.EVENT_DELETION, tags, "delete");
    return sendEvent(event);
  }

  Event sendRepost(String id) {
    Event event = Event(
        _publicKey,
        kind.EventKind.REPOST,
        [
          ["e", id]
        ],
        "#[0]");
    return sendEvent(event);
  }

  Event sendTextNote(String text, [List<dynamic> tags = const []]) {
    Event event = Event(_publicKey, EventKind.textNote, tags, text);
    return sendEvent(event);
  }

  // Event sendMetaData({String? name, String? about, String? picture}) {
  //   Map<String, String> params = {};
  //   ({'name': name, 'about': about, 'picture': picture}).forEach((key, value) {
  //     if (value != null) params[key] = value;
  //   });

  //   if (params.isEmpty) throw ArgumentError("No metadata provided");

  //   final metaData = jsonEncode(params);
  //   final event = Event(_publicKey, EventKind.metaData, [], metaData);
  //   return sendEvent(event);
  // }

  Event recommendServer(String url) {
    if (!url.contains(RegExp(
        r'^(wss?:\/\/)([0-9]{1,3}(?:\.[0-9]{1,3}){3}|[^:]+):?([0-9]{1,5})?$'))) {
      throw ArgumentError.value(url, 'url', 'Not a valid relay URL');
    }
    final event = Event(_publicKey, EventKind.recommendServer, [], url);
    return sendEvent(event);
  }

  Event sendContactList(CustContactList contacts) {
    final tags = contacts.toJson();
    final event = Event(_publicKey, EventKind.contactList, tags, "");
    return sendEvent(event);
  }

  Event sendEvent(Event event) {
    if (_privateKey.isEmpty) {
      throw StateError("Private key is missing. Message can't be signed.");
    }
    event.doProofOfWork(powDifficulty);
    event.sign(_privateKey);
    pool.send(["EVENT", event.toJson()]);
    return event;
  }

  void close() {
    var addrs = pool.list;
    for (var addr in addrs) {
      pool.remove(addr);
    }
  }
}
