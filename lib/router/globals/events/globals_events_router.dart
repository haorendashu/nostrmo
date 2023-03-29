import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/dio_util.dart';
import 'package:nostrmo/util/string_util.dart';

import 'globals_event_item_component.dart';

class GlobalsEventsRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GlobalsEventsRouter();
  }
}

class _GlobalsEventsRouter extends CustState<GlobalsEventsRouter> {
  List<String> ids = [];

  @override
  Widget doBuild(BuildContext context) {
    if (ids.isEmpty) {
      return Container(
        child: Center(
          child: Text("GlobalsEventsRouter"),
        ),
      );
    }

    return Container(
      child: ListView.builder(
        itemBuilder: (context, index) {
          var id = ids[index];
          if (StringUtil.isBlank(id)) {
            return Container();
          }

          return GlobalEventItemComponent(
            eventId: id,
          );
        },
        itemCount: ids.length,
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    var str = await DioUtil.getStr(Base.INDEXS_EVENTS);
    print(str);
    if (StringUtil.isNotBlank(str)) {
      ids.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        ids.add(itf as String);
      }
      print(ids);
      setState(() {});
    }
  }
}
