import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/data/event_mem_box.dart';
import 'package:nostrmo/util/peddingevents_lazy_function.dart';
import 'package:provider/provider.dart';

import '../../client/event_kind.dart' as kind;
import '../../client/filter.dart';
import '../../client/nip19/nip19.dart';
import '../../component/appbar4stack.dart';
import '../../component/cust_state.dart';
import '../../component/event/event_list_component.dart';
import '../../component/user/metadata_component.dart';
import '../../data/metadata.dart';
import '../../main.dart';
import '../../provider/metadata_provider.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';

class UserRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _UserRouter();
  }
}

class _UserRouter extends CustState<UserRouter>
    with PenddingEventsLazyFunction {
  late ScrollController _scrollController;

  String? pubkey;

  bool showTitle = false;

  bool showAppbarBG = false;

  List<Event>? events;

  EventMemBox box = EventMemBox();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      var _showTitle = false;
      var _showAppbarBG = false;

      var offset = _scrollController.offset;
      if (offset > showTitleHeight) {
        _showTitle = true;
      }
      if (offset > showAppbarBGHeight) {
        _showAppbarBG = true;
      }

      if (_showTitle != showTitle || _showAppbarBG != showAppbarBG) {
        setState(() {
          showTitle = _showTitle;
          showAppbarBG = _showAppbarBG;
        });
      }
    });
  }

  /// the offset to show title, bannerHeight + 50;
  double showTitleHeight = 50;

  /// the offset to appbar background color, showTitleHeight + 100;
  double showAppbarBGHeight = 50 + 100;

  @override
  Widget doBuild(BuildContext context) {
    if (StringUtil.isBlank(pubkey)) {
      pubkey = RouterUtil.routerArgs(context) as String?;
      if (StringUtil.isBlank(pubkey)) {
        RouterUtil.back(context);
      }
      events ??= followEventProvider.eventsByPubkey(pubkey!);
      if (events != null && events!.isNotEmpty) {
        box.addList(events!);
      }
    }

    var mediaData = MediaQuery.of(context);
    var paddingTop = mediaData.padding.top;
    var maxWidth = mediaData.size.width;

    showTitleHeight = maxWidth / 3 + 50;
    showAppbarBGHeight = showTitleHeight + 100;

    return Selector<MetadataProvider, Metadata?>(
      shouldRebuild: (previous, next) {
        return previous != next;
      },
      selector: (context, _metadataProvider) {
        return _metadataProvider.getMetadata(pubkey!);
      },
      builder: (context, metadata, child) {
        Color? appbarBackgroundColor = Colors.transparent;
        if (showAppbarBG) {
          appbarBackgroundColor = Colors.white.withOpacity(0.5);
        }
        Widget? appbarTitle;
        if (showTitle) {
          String nip19Name = Nip19.encodeSimplePubKey(pubkey!);
          String displayName = nip19Name;
          if (metadata != null) {
            if (StringUtil.isNotBlank(metadata.displayName)) {
              displayName = metadata.displayName!;
            }

            appbarTitle = Container(
              alignment: Alignment.center,
              child: Text(
                displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            );
          }
        }
        var appBar = Appbar4Stack(
          backgroundColor: appbarBackgroundColor,
          title: appbarTitle,
        );

        return Scaffold(
            body: Stack(
          children: [
            NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverToBoxAdapter(
                    child: MetadataComponent(
                      pubKey: pubkey!,
                      metadata: metadata,
                    ),
                  ),
                ];
              },
              body: MediaQuery.removePadding(
                removeTop: true,
                context: context,
                child: ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    var event = box.get(index);
                    if (event == null) {
                      return null;
                    }
                    return EventListComponent(
                      event: event,
                      pagePubkey: pubkey,
                    );
                  },
                  itemCount: box.length(),
                ),
              ),
            ),
            Positioned(
              top: paddingTop,
              child: Container(
                width: maxWidth,
                child: appBar,
              ),
            ),
          ],
        ));
      },
    );
  }

  var subscribeId = StringUtil.rndNameStr(16);

  @override
  Future<void> onReady(BuildContext context) async {
    // load event from relay
    var filter = Filter(
      kinds: [kind.EventKind.TEXT_NOTE],
      until: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      authors: [pubkey!],
      limit: 100,
    );
    subscribeId = StringUtil.rndNameStr(16);
    nostr!.pool.query([filter.toJson()], onEvent, subscribeId);
  }

  void onEvent(event) {
    lazy(event, (list) {
      box.addList(list);
      setState(() {});
    }, null);
  }

  @override
  void dispose() {
    super.dispose();

    try {
      nostr!.pool.unsubscribe(subscribeId);
    } catch (e) {}
  }
}
