import 'dart:async';

import 'package:flutter/material.dart';

abstract class CustState<T extends StatefulWidget> extends State<T> {
  bool isInited = false;

  bool readyComplete = false;

  bool disposed = false;

  @override
  Widget build(BuildContext context) {
    Widget w = doBuild(context);

    if (!isInited) {
      isInited = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        this.onReady(context);
        readyComplete = true;
      });
    }

    return w;
  }

  Widget doBuild(BuildContext context);

  Future<void> onReady(BuildContext context);

  @override
  void dispose() {
    super.dispose();
    disposed = true;
  }

  // @override
  // void initState() {
  //   super.initState();
  // }
}
