import 'package:nostr_dart/nostr_dart.dart';

mixin PenddingEventsLaterFunction {
  int laterTimeMS = 200;

  bool latering = false;

  List<Event> penddingEvents = [];

  void later(Event event, Function(List<Event>) func, Function? completeFunc) {
    penddingEvents.add(event);
    if (latering) {
      return;
    }

    latering = true;
    Future.delayed(Duration(milliseconds: laterTimeMS), () {
      latering = false;
      func(penddingEvents);
      penddingEvents.clear();
      if (completeFunc != null) {
        completeFunc();
      }
    });
  }
}
