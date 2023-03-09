mixin LazyFunction {
  int lazyTimeMS = 200;

  bool lazying = false;

  void lazy(Function func, Function? completeFunc) {
    if (lazying) {
      return;
    }

    lazying = true;
    Future.delayed(Duration(milliseconds: lazyTimeMS), () {
      lazying = false;
      func();
      if (completeFunc != null) {
        completeFunc();
      }
    });
  }
}
