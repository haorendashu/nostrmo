import 'package:nostr_dart/nostr_dart.dart';

mixin PenddingEventsLazyFunction {
  int lazyTimeMS = 200;

  bool lazying = false;

  List<Event> penddingEvents = [];

  void lazy(Event event, Function(List<Event>) func, Function? completeFunc) {
    penddingEvents.add(event);
    if (lazying) {
      return;
    }

    lazying = true;
    Future.delayed(Duration(milliseconds: lazyTimeMS), () {
      lazying = false;
      func(penddingEvents);
      penddingEvents.clear();
      if (completeFunc != null) {
        completeFunc();
      }
    });
  }
}
