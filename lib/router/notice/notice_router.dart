import 'package:flutter/material.dart';
import 'package:nostrmo/client/upload/nostr_build_uploader.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

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
