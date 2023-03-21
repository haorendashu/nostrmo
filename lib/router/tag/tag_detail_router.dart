import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';

import '../../client/filter.dart';
import '../../component/cust_state.dart';
import '../../component/event/event_list_component.dart';
import '../../consts/base.dart';
import '../../data/event_mem_box.dart';
import '../../main.dart';
import '../../util/peddingevents_lazy_function.dart';
import '../../util/router_util.dart';
import '../../client/event_kind.dart' as kind;
import '../../util/string_util.dart';

class TagDetailRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TagDetailRouter();
  }
}

class _TagDetailRouter extends CustState<TagDetailRouter>
    with PenddingEventsLazyFunction {
  EventMemBox box = EventMemBox();

  ScrollController _controller = ScrollController();

  bool showTitle = false;

  double tagHeight = 80;

  String? tag;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.offset > tagHeight * 0.8 && !showTitle) {
        setState(() {
          showTitle = true;
        });
      } else if (_controller.offset < tagHeight * 0.8 && showTitle) {
        setState(() {
          showTitle = false;
        });
      }
    });
  }

  @override
  Widget doBuild(BuildContext context) {
    if (StringUtil.isBlank(tag)) {
      var arg = RouterUtil.routerArgs(context);
      if (arg != null && arg is String) {
        tag = arg;
      }
    }
    if (StringUtil.isBlank(tag)) {
      RouterUtil.back(context);
      return Container();
    }

    var themeData = Theme.of(context);
    var cardColor = themeData.cardColor;
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;

    Widget? appBarTitle;
    if (showTitle) {
      appBarTitle = Text(
        tag!,
        style: TextStyle(
          fontSize: bodyLargeFontSize,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(Icons.arrow_back_ios),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_horiz),
          ),
        ],
        title: appBarTitle,
      ),
      body: NestedScrollView(
        controller: _controller,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverToBoxAdapter(
              child: Container(
                child: Text(
                  tag!,
                  style: TextStyle(
                    fontSize: bodyLargeFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                height: tagHeight,
                color: cardColor,
                alignment: Alignment.center,
                margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
              ),
            ),
          ];
        },
        body: ListView.builder(
          itemBuilder: (context, index) {
            var event = box.get(index);
            if (event == null) {
              return null;
            }

            return EventListComponent(event: event);
          },
          itemCount: box.length(),
        ),
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    // tag query
    // https://github.com/nostr-protocol/nips/blob/master/12.md
    // but there arg many relay don't support.
    var filter = Filter(kinds: [kind.EventKind.TEXT_NOTE], limit: 100);
    var queryArg = filter.toJson();
    var plainTag = tag!.replaceFirst("#", "");
    queryArg["#r"] = [plainTag];
    nostr!.pool.query([queryArg], onEvent);
  }

  void onEvent(Event event) {
    print(event.toJson());
    lazy(event, (list) {
      box.addList(list);
      setState(() {});
    }, null);
  }
}
