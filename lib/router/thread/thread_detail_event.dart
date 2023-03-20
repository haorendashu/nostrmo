import 'package:nostr_dart/nostr_dart.dart';

class ThreadDetailEvent {
  Event event;

  List<ThreadDetailEvent> subItems = [];

  ThreadDetailEvent({required this.event});
}
