import 'package:nostr/nostr.dart';
import 'package:nostrmo/client/relay.dart';
import 'package:nostrmo/client/subscription.dart';
import 'package:nostrmo/data/relay_status.dart';

class RelayBox {
  static RelayBox? _box;

  static Future<RelayBox> getInstance() async {
    _box ??= RelayBox();
    return _box!;
  }

  List<Relay> _relays = [];

  Map<String, Subscription> subscriptions = {};

  Future<void> addRelay(RelayStatus relayStatus) async {
    var relay = Relay(relayStatus);
    await relay.init();
    _relays.add(relay);
  }

  void subscribe(Subscription subscription) {}

  void unSubscribe(String subscribeId) {}
}

typedef OnEventFunc = void Function(Event event, Relay relay);
