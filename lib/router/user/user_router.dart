import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';

import '../../component/event/event_list_component.dart';
import '../../component/user/metadata_component.dart';
import '../../data/metadata.dart';
import '../../provider/metadata_provider.dart';

class UserRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _UserRouter();
  }
}

class _UserRouter extends State<UserRouter> {
  late ScrollController _scrollController;

  String? pubKey;

  bool headerWhite = false;

  List<Event> events = [];

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      ///监听滚动位置设置导航栏颜色
      setState(() {
        headerWhite = _scrollController.offset > 400 ? true : false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    pubKey = RouterUtil.routerArgs(context) as String?;
    if (StringUtil.isBlank(pubKey)) {
      RouterUtil.back(context);
    }

    return Selector<MetadataProvider, Metadata?>(
      shouldRebuild: (previous, next) {
        return previous != next;
      },
      selector: (context, _metadataProvider) {
        return _metadataProvider.getMetadata(pubKey!);
      },
      builder: (context, metadata, child) {
        return Scaffold(
          body: Column(
            children: [
              MetadataComponent(
                pubKey: pubKey!,
                metadata: metadata,
              ),
              Expanded(child: buildSliverBody(context)),
            ],
          ),
        );

        // return Scaffold(
        //   body: NestedScrollView(
        //       controller: _scrollController,
        //       headerSliverBuilder: _headerSliverBuilder,
        //       // body: Text('data'),
        //       body: buildSliverBody(context)),
        // );
      },
    );
  }

  List<Widget> _headerSliverBuilder(
      BuildContext context, bool innerBoxIsScrolled) {
    return <Widget>[SliverAppBar()];
  }

  Widget buildSliverBody(BuildContext context) {
    return Container(
      child: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          var event = events[index];
          return EventListComponent(event: event);
        },
        itemCount: events.length,
      ),
    );
  }
}
