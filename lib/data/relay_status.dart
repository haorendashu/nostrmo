import '../consts/client_connected.dart';

class RelayStatus {
  String addr;

  bool writeAccess;

  bool readAccess;

  RelayStatus(this.addr, {this.writeAccess = true, this.readAccess = true});

  int connected = ClientConneccted.UN_CONNECT;

  // bool noteAble = true;
  // bool dmAble = true;
  // bool profileAble = true;
  // bool globalAble = true;

  int noteReceived = 0;

  int error = 0;
}
