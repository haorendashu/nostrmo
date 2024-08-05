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
    dt ??= DateTime.now();
    lastNoteTime = dt;
  }

  int _queryNum = 0;

  int get queryNum => _queryNum;

  void onQuery({DateTime? dt}) {
    _queryNum++;
    dt ??= DateTime.now();
    lastQueryTime = dt;
  }

  int _error = 0;

  int get error => _error;

  void onError({DateTime? dt}) {
    _error++;
    dt ??= DateTime.now();
    lastErrorTime = dt;
  }

  DateTime connectTime = DateTime.now();

  DateTime? lastQueryTime;

  DateTime? lastNoteTime;

  DateTime? lastErrorTime;
}
