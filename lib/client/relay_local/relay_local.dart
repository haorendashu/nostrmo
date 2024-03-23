import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/client/relay/relay_info.dart';
import 'package:nostrmo/client/relay_local/relay_local_db.dart';

import '../../consts/client_connected.dart';
import '../relay/relay.dart';

class RelayLocal extends Relay {
  static const URL = "Local Relay";

  RelayLocalDB relayLocalDB;

  RelayLocal(super.url, super.relayStatus, this.relayLocalDB) {
    super.relayStatus.connected = ClientConneccted.CONNECTED;

    info = RelayInfo(
        "Local Relay",
        "This is a local relay. It will cache some event.",
        "29320975df855fe34a7b45ada2421e2c741c37c0136901fe477133a91eb18b07",
        "29320975df855fe34a7b45ada2421e2c741c37c0136901fe477133a91eb18b07",
        ["1"],
        "Nostrmo",
        "0.1.0");
  }

  void broadcaseToLocal(Map<String, dynamic> event) {
    relayLocalDB.addEvent(event);
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> doConnect() async {
    return true;
  }

  @override
  bool send(List message) {
    // all messages were resend by the local, so we didn't check sig here.

    if (message.isNotEmpty) {
      var action = message[0];
      if (action == "EVENT") {
        doEvent(message);
      } else if (action == "REQ") {
        doReq(message);
      } else if (action == "CLOSE") {
        // this relay only use to handle cache event, so it wouldn't push new event to client.
      } else if (action == "AUTH") {
        // don't handle the message
      } else if (action == "COUNT") {
        doCount(message);
      }
    }
    return true;
  }

  void doEvent(List message) {
    var event = message[1];
    var id = event["id"];
    var eventKind = event["kind"];

    if (eventKind == EventKind.EVENT_DELETION) {
      var tags = event["tags"];
      var pubkey = event["pubkey"];
      if (tags is List && tags.isNotEmpty) {
        for (var tag in tags) {
          if (tag is List && tag.isNotEmpty && tag.length > 1) {
            var k = tag[0];
            var v = tag[1];
            if (k == "e") {
              relayLocalDB.deleteEvent(pubkey, v);
            } else if (k == "a") {
              // TODO should add support delete by aid
            }
          }
        }
      }
    } else {
      // maybe it shouldn't insert here, due to it doesn't had a source.
      relayLocalDB.addEvent(event);
    }

    // send callback
    onMessage!(this, ["OK", id, true]);
  }

  Future<void> doReq(List message) async {
    if (message.length > 2) {
      var subsctionId = message[1];

      for (var i = 2; i < message.length; i++) {
        var filter = message[i];

        var events = await relayLocalDB.doQueryEvent(filter);
        for (var event in events) {
          // send callback
          onMessage!(this, ["EVENT", subsctionId, event]);
        }
      }

      // query complete, send callback
      onMessage!(this, ["EOSE", subsctionId]);
    }
  }

  Future<void> doCount(List message) async {
    if (message.length > 2) {
      var subsctionId = message[1];
      var filter = message[2];
      var count = await relayLocalDB.doQueryCount(filter);

      // send callback
      onMessage!(this, [
        "COUNT",
        subsctionId,
        {"count": count}
      ]);
    }
  }
}
