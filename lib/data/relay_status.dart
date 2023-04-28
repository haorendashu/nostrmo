import '../consts/client_connected.dart';

class RelayStatus {
  String addr;

  RelayStatus(this.addr);

  int connected = ClientConneccted.UN_CONNECT;

  // bool noteAble = true;
  // bool dmAble = true;
  // bool profileAble = true;
  // bool globalAble = true;

  int noteReceived = 0;

  int error = 0;
}
