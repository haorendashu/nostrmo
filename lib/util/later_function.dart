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
}
