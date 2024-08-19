import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_relation.dart';

class EventTraceInfo {
  Event event;

  late EventRelation eventRelation;

  EventTraceInfo(this.event) {
    eventRelation = EventRelation.fromEvent(event);
  }
}
