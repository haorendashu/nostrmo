import 'package:flutter/material.dart';

import '../../consts/router_path.dart';
import '../../util/router_util.dart';

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
            RouterUtil.router(context, RouterPath.EDITOR);
          },
          child: Text("NOTICE"),
        ),
      ),
    );
  }
}
