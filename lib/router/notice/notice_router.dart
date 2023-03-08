import 'package:flutter/material.dart';

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
        child: Text("NOTICE"),
      ),
    );
  }
}
