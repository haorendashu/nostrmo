import 'dart:convert';
import 'dart:isolate';

import 'package:nostrmo/client/event.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'relay_isolate.dart';

class RelayIsolateWorker {
  RelayIsolateConfig config;

  WebSocketChannel? wsChannel;

  RelayIsolateWorker({
    required this.config,
  });

  void run() {
    ReceivePort mainToSubReceivePort = ReceivePort();
    var mainToSubSendPort = mainToSubReceivePort.sendPort;
    config.subToMainSendPort.send(mainToSubSendPort);

    mainToSubReceivePort.listen((message) {
      if (message is String) {
        // this is the msg need to sended.
        if (wsChannel != null) {
          wsChannel!.sink.add(message);
        }
      } else if (message is int) {
        // this is const msg.
        // print("msg is $message ${config.url}");
        if (message == RelayIsolateMsgs.CONNECT &&
            (wsChannel == null || wsChannel!.closeCode != null)) {
          _closeWS(wsChannel);
          // print("!!!!");
          wsChannel = handleWS();
          config.subToMainSendPort.send(RelayIsolateMsgs.CONNECTED);
        } else if (message == RelayIsolateMsgs.DIS_CONNECT) {
          var result = _closeWS(wsChannel);
          if (result) {
            config.subToMainSendPort.send(RelayIsolateMsgs.DIS_CONNECTED);
          }
        }
      }
    });

    wsChannel = handleWS();
  }

  static void runRelayIsolate(RelayIsolateConfig config) {
    var worker = RelayIsolateWorker(config: config);
    worker.run();
  }

  WebSocketChannel? handleWS() {
    String url = config.url;
    SendPort subToMainSendPort = config.subToMainSendPort;

    final wsUrl = Uri.parse(url);
    try {
      print("Begin to connect ${config.url}");
      wsChannel = WebSocketChannel.connect(wsUrl);
      print("Connect complete! ${config.url}");
      wsChannel!.stream.listen((message) {
        List<dynamic> json = jsonDecode(message);
        if (json.length > 2) {
          final messageType = json[0];
          if (messageType == 'EVENT') {
            final event = Event.fromJson(json[2]);
            if (config.eventCheck) {
              // event need to check
              if (!event.isValid || !event.isSigned) {
                // check false
                return;
              }
            }
          }
        }
        subToMainSendPort.send(json);
      }, onError: (error) async {
        _closeWS(wsChannel);
        wsChannel = null;
        subToMainSendPort.send(RelayIsolateMsgs.DIS_CONNECTED);
      }, onDone: () {
        print("Websocket stream closed by remote:  $url");
        _closeWS(wsChannel);
        subToMainSendPort.send(RelayIsolateMsgs.DIS_CONNECTED);
      });
      subToMainSendPort.send(RelayIsolateMsgs.CONNECTED);

      return wsChannel;
    } catch (e) {
      _closeWS(wsChannel);
      subToMainSendPort.send(RelayIsolateMsgs.DIS_CONNECTED);
    }

    return null;
  }

  bool _closeWS(WebSocketChannel? wsChannel) {
    if (wsChannel == null) {
      return false;
    }

    try {
      wsChannel.sink.close();
    } catch (e) {
      print("ws close error ${e.toString()}");
    }

    wsChannel = null;
    return true;
  }
}
