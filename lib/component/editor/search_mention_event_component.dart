import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostr_sdk/utils/when_stop_function.dart';

import '../../consts/base.dart';
import '../../data/event_find_util.dart';
import '../../util/router_util.dart';
import '../event/event_list_component.dart';
import 'search_mention_component.dart';

class SearchMentionEventComponent extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SearchMentionEventComponent();
  }
}

class _SearchMentionEventComponent extends State<SearchMentionEventComponent>
    with WhenStopFunction {
  @override
  Widget build(BuildContext context) {
    return SaerchMentionComponent(
      resultBuildFunc: resultBuild,
      handleSearchFunc: handleSearch,
    );
  }

  Widget resultBuild() {
    return Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        bottom: Base.BASE_PADDING_HALF,
      ),
      child: ListView.builder(
        itemBuilder: (context, index) {
          var event = events[index];
          return GestureDetector(
            onTap: () {
              RouterUtil.back(context, event.id);
            },
            child: EventListComponent(
              event: event,
              jumpable: false,
            ),
          );
        },
        itemCount: events.length,
      ),
    );
  }

  static const int searchMemLimit = 100;

  List<Event> events = [];

  Future<void> handleSearch(String? text) async {
    events.clear();
    if (StringUtil.isNotBlank(text)) {
      var list = await EventFindUtil.findEvent(text!, limit: searchMemLimit);
      setState(() {
        events = list;
      });
    }
  }
}
