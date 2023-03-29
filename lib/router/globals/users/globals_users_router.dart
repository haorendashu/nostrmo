import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:provider/provider.dart';

import '../../../component/user/metadata_component.dart';
import '../../../consts/base.dart';
import '../../../data/metadata.dart';
import '../../../provider/metadata_provider.dart';
import '../../../util/dio_util.dart';
import '../../../util/string_util.dart';

class GlobalsUsersRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GlobalsUsersRouter();
  }
}

class _GlobalsUsersRouter extends CustState<GlobalsUsersRouter> {
  List<String> pubkeys = [];

  @override
  Widget doBuild(BuildContext context) {
    if (pubkeys.isEmpty) {
      return Container(
        child: Center(
          child: Text("GlobalsEventsRouter"),
        ),
      );
    }

    return Container(
      child: ListView.builder(
        itemBuilder: (context, index) {
          var pubkey = pubkeys[index];
          if (StringUtil.isBlank(pubkey)) {
            return Container();
          }

          return Container(
            margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
            child: Selector<MetadataProvider, Metadata?>(
              builder: (context, metadata, child) {
                return MetadataComponent(
                  pubKey: pubkey,
                  metadata: metadata,
                  jumpable: true,
                );
              },
              selector: (context, _provider) {
                return _provider.getMetadata(pubkey);
              },
            ),
          );
        },
        itemCount: pubkeys.length,
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    var str = await DioUtil.getStr(Base.INDEXS_CONTACTS);
    if (StringUtil.isNotBlank(str)) {
      pubkeys.clear();
      var itfs = jsonDecode(str!);
      for (var itf in itfs) {
        pubkeys.add(itf as String);
      }
      setState(() {});
    }
  }
}
