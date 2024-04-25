import 'package:nostrmo/client/event.dart';

import '../../client/event_relation.dart';

class EventTraceInfo {
  Event event;

  late EventRelation eventRelation;

  EventTraceInfo(this.event) {
    eventRelation = EventRelation.fromEvent(event);
  }
}
