import 'package:flutter/material.dart';

import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import '../edit/editor_router.dart';

class NoticeRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _NoticeRouter();
  }
}

class _NoticeRouter extends State<NoticeRouter> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: GestureDetector(
          onTap: () {
            EditorRouter.open(context);
          },
          child: Text("NOTICE"),
        ),
      ),
    );
  }
}
