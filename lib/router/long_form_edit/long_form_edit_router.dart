import 'package:flutter/material.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/editor/editor_mixin.dart';

class LongFormEditRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LongFormEditRouter();
  }
}

class _LongFormEditRouter extends CustState<LongFormEditRouter>
    with EditorMixin {
  @override
  void initState() {
    super.initState();
    handleFocusInit();
  }

  @override
  Future<void> onReady(BuildContext context) async {}

  @override
  Widget doBuild(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

  @override
  BuildContext getContext() {
    return context;
  }

  @override
  String? getPubkey() {
    return null;
  }

  @override
  List getTags() {
    return [];
  }

  @override
  List getTagsAddedWhenSend() {
    return [];
  }

  @override
  bool isDM() {
    return false;
  }

  @override
  void updateUI() {
    setState(() {});
  }
}
