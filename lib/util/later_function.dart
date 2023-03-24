mixin LaterFunction {
  int laterTimeMS = 200;

  bool latering = false;

  void later(Function func, Function? completeFunc) {
    if (latering) {
      return;
    }

    latering = true;
    Future.delayed(Duration(milliseconds: laterTimeMS), () {
      latering = false;
      func();
      if (completeFunc != null) {
        completeFunc();
      }
    });
  }

  int whenStopMS = 200;

  int stopTime = 0;

  bool waitingStop = false;

  void whenStop(Function func) {
    _updateStopTime();
    if (!waitingStop) {
      waitingStop = true;
      _goWaitForStop(func);
    }
  }

  void _updateStopTime() {
    stopTime = DateTime.now().millisecondsSinceEpoch + whenStopMS;
  }

  void _goWaitForStop(Function func) {
    Future.delayed(Duration(milliseconds: whenStopMS), () {
      var nowMS = DateTime.now().millisecondsSinceEpoch;
      if (nowMS >= stopTime) {
        waitingStop = false;
        func();
      } else {
        _goWaitForStop(func);
      }
    });
  }
}
