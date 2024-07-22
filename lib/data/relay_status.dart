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

  int _noteReceived = 0;

  int get noteReceived => _noteReceived;

  bool authed = false;

  void noteReceive({DateTime? dt}) {
    _noteReceived++;
    if (dt != null) {
      lastNoteTime = dt;
    } else {
      lastNoteTime = DateTime.now();
    }
  }

  int _error = 0;

  int get error => _error;

  void onError({DateTime? dt}) {
    _error++;
    if (dt != null) {
      lastErrorTime = dt;
    } else {
      lastErrorTime = DateTime.now();
    }
  }

  DateTime connectTime = DateTime.now();

  DateTime? lastQueryTime;

  DateTime? lastNoteTime;

  DateTime? lastErrorTime;
}
