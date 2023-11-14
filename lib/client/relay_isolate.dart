import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';

import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/relay_isolate_worker.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/main.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../consts/client_connected.dart';
import '../data/relay_status.dart';
import 'relay.dart';

// The real relay, whick is run in other isolate.
// It can move jsonDecode and event id check and sign check from main Isolate
class RelayIsolate extends Relay {
  RelayIsolate(String url, RelayStatus relayStatus,
      {WriteAccess access = WriteAccess.readWrite})
      : super(url, relayStatus, access: access);

  Isolate? isolate;

  ReceivePort? subToMainReceivePort;

  SendPort? mainToSubSendPort;

  Completer<bool>? relayConnectResultComplete;

  @override
  Future<bool> connect() async {
    if (subToMainReceivePort == null) {
      relayStatus.connected = ClientConneccted.CONNECTING;
      getRelayInfo(url);

      // never run isolate, begin to run
      subToMainReceivePort = ReceivePort("relay_stm_$url");
      subToMainListener(subToMainReceivePort!);

      relayConnectResultComplete = Completer();
      isolate = await Isolate.spawn(
        RelayIsolateWorker.runRelayIsolate,
        RelayIsolateConfig(
          url: url,
          subToMainSendPort: subToMainReceivePort!.sendPort,
          eventCheck: settingProvider.eventSignCheck == OpenStatus.OPEN,
        ),
      );
      // isolate has run and return a completer.future, wait for subToMain msg to complete this completer.
      return relayConnectResultComplete!.future;
    } else {
      // the isolate had bean run
      if (relayStatus.connected == ClientConneccted.CONNECTED) {
        // relay has bean connected, return true
        return true;
      } else {
        // haven't connected
        if (relayConnectResultComplete != null) {
          return relayConnectResultComplete!.future;
        } else {
          // this maybe relay had disconnect after connected, try to connected again.
          if (mainToSubSendPort != null) {
            // send connect msg
            mainToSubSendPort!.send(RelayIsolateMsgs.CONNECT);
            // wait connected msg.
            relayConnectResultComplete = Completer();
            return relayConnectResultComplete!.future;
          }
        }
      }
    }

    return false;
  }

  @override
  Future<void> disconnect() async {
    if (relayStatus.connected != ClientConneccted.UN_CONNECT) {
      relayStatus.connected = ClientConneccted.UN_CONNECT;
      if (mainToSubSendPort != null) {
        mainToSubSendPort!.send(RelayIsolateMsgs.DIS_CONNECT);
      }
    }
  }

  @override
  bool send(List message) {
    if (mainToSubSendPort != null &&
        relayStatus.connected == ClientConneccted.CONNECTED) {
      final encoded = jsonEncode(message);
      // print(encoded);
      mainToSubSendPort!.send(encoded);
      return true;
    }

    return false;
  }

  void subToMainListener(ReceivePort receivePort) {
    receivePort.listen((message) {
      if (message is int) {
        // this is const msg.
        // print("msg is $message $url");
        if (message == RelayIsolateMsgs.CONNECTED) {
          relayStatus.connected = ClientConneccted.CONNECTED;
          relayStatusCallback!();
          if (relayConnectResultComplete != null) {
            relayConnectResultComplete!.complete(true);
            relayConnectResultComplete = null;
          }
        } else if (message == RelayIsolateMsgs.DIS_CONNECTED) {
          onError("Websocket error $url", reconnect: true);
          if (relayConnectResultComplete != null) {
            relayConnectResultComplete!.complete(false);
            relayConnectResultComplete = null;
          }
        }
      } else if (message is List && onMessage != null) {
        onMessage!(this, message);
      } else if (message is SendPort) {
        mainToSubSendPort = message;
      }
    });
  }

  @override
  void dispose() {
    if (isolate != null) {
      isolate!.kill();
    }
  }
}

class RelayIsolateConfig {
  final String url;
  final SendPort subToMainSendPort;
  final bool eventCheck;

  RelayIsolateConfig({
    required this.url,
    required this.subToMainSendPort,
    required this.eventCheck,
  });
}

class RelayIsolateMsgs {
  static const int CONNECT = 1;

  static const int DIS_CONNECT = 2;

  static const int CONNECTED = 101;

  static const int DIS_CONNECTED = 102;
}
