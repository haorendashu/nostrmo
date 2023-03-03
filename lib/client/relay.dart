import 'dart:convert';
import 'dart:io';

import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/data/relay_status.dart';
import 'package:http/http.dart' as http;

import 'relay_info.dart';

class Relay {
  RelayStatus status;

  RelayInfo? relayInfo;

  Relay(this.status);

  WebSocket? webSocket;

  Future<void> init() async {
    var client = http.Client();
    try {
      final response = await client.get(
          Uri.parse(status.addr).replace(scheme: 'https'),
          headers: {'Accept': 'application/nostr+json'});
      final decodedResponse = jsonDecode(response.body) as Map;
      relayInfo = RelayInfo.fromJson(decodedResponse);
      print("RelayInfo load complete");
    } finally {
      client.close();
    }

    webSocket = await WebSocket.connect(status.addr,
        headers: {"User-Agent": Base.userAgent()});
    webSocket!.pingInterval = Duration(seconds: 30);
    print("webSocket initComplete");

    // TODO check relayInfo

    webSocket!.listen((event) {
      print("webSocket receive event:");
      print(event);
    });

    // Filter filter = Filter(
    //   kinds:
    // );
  }
}
