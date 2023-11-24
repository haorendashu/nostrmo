import 'dart:convert';
import 'package:http/http.dart' as http;
import 'relay_info.dart';

class RelayInfoUtil {
  static Future<RelayInfo> get(String url) async {
    final response = await http.get(Uri.parse(url).replace(scheme: 'https'),
        headers: {'Accept': 'application/nostr+json'});
    final decodedResponse = jsonDecode(response.body) as Map;
    return RelayInfo.fromJson(decodedResponse);
  }
}
