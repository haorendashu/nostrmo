import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';

import '../../../component/cust_state.dart';
import '../../../consts/base.dart';
import '../../../util/dio_util.dart';
import '../../../util/string_util.dart';

class GlobalsTagsRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GlobalsTagsRouter();
  }
}

class _GlobalsTagsRouter extends CustState<GlobalsTagsRouter> {
  List<String> topics = [];

  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;

    if (topics.isEmpty) {
      return Container(
        child: Center(
          child: Text("GlobalsTagsRouter"),
        ),
      );
    } else {
      List<Widget> list = [];
      for (var topic in topics) {
        list.add(GestureDetector(
          onTap: () {
            RouterUtil.router(context, RouterPath.TAG_DETAIL, topic);
          },
          child: Container(
            padding: EdgeInsets.all(Base.BASE_PADDING_HALF),
            decoration: BoxDecoration(
              color: mainColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              topic,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ));
      }

      return Container(
        // padding: EdgeInsets.all(Base.BASE_PADDING),
        child: Center(
          child: Wrap(
            children: list,
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
          ),
        ),
      );
    }
  }

  @override
  Future<void> onReady(BuildContext context) async {
    var str = await DioUtil.getStr(Base.INDEXS_TOPICS);
    if (StringUtil.isNotBlank(str)) {
      topics.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        topics.add(itf as String);
      }
      setState(() {});
    }
  }
}
