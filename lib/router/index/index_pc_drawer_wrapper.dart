import 'package:flutter/material.dart';

import 'index_drawer_content.dart';

class IndexPcDrawerWrapper extends StatefulWidget {
  double fixWidth;

  IndexPcDrawerWrapper({
    required this.fixWidth,
  });

  @override
  State<StatefulWidget> createState() {
    return _IndexPcDrawerWrapper();
  }
}

class _IndexPcDrawerWrapper extends State<IndexPcDrawerWrapper> {
  static const double SMALL_WIDTH = 80;

  bool? smallMode;

  bool? forceSmallMode;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = widget.fixWidth;
    if (widget.fixWidth <= 170) {
      smallMode = true;
    } else {
      smallMode = false;
    }
    if (currentMode) {
      width = SMALL_WIDTH;
    }

    return IndexPcDrawerWrapperCallback(
      toggle: toggleSize,
      child: Container(
        width: width,
        child: IndexDrawerContnetComponnent(
          smallMode: currentMode,
        ),
      ),
    );
  }

  bool get currentMode {
    return forceSmallMode != null ? forceSmallMode! : smallMode!;
  }

  void toggleSize() {
    if (forceSmallMode == null) {
      setState(() {
        forceSmallMode = !smallMode!;
      });
    } else {
      setState(() {
        forceSmallMode = !forceSmallMode!;
      });
    }
  }
}

class IndexPcDrawerWrapperCallback extends InheritedWidget {
  Function toggle;

  IndexPcDrawerWrapperCallback({required this.toggle, required super.child});

  static IndexPcDrawerWrapperCallback? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<IndexPcDrawerWrapperCallback>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
