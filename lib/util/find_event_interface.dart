import 'package:nostr_dart/nostr_dart.dart';

abstract class FindEventInterface {
  List<Event> findEvent(String str, {int? limit = 5});
}
