import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_cache_manager/src/web/file_service.dart';
import 'package:http/http.dart' as http;
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/hash_util.dart';

class RetryHttpFileServcie extends FileService {
  final http.Client _httpClient;

  RetryHttpFileServcie({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String>? headers}) async {
    // log("begin to load image from ${url}");
    try {
      final req = http.Request('GET', Uri.parse(url));
      if (headers != null) {
        req.headers.addAll(headers);
      }
      final httpResponse =
          await _httpClient.send(req).timeout(Duration(seconds: 60));

      var response = HttpGetResponse(httpResponse);
      if (response.statusCode > 299) {
        return retry(url, headers: headers);
      }
      return response;
    } catch (e) {
      // error! use nostrmo proxy service to download it
      return retry(url, headers: headers);
    }
  }

  Future<FileServiceResponse> retry(String url,
      {Map<String, String>? headers}) async {
    var base64Url = base64UrlEncode(utf8.encode(url));
    int t = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var sign = HashUtil.md5("$base64Url$t${Base.IMAGE_PROXY_SERVICE_KEY}");

    // t and sign arg set to head
    url = "${Base.IMAGE_PROXY_SERVICE}$base64Url";
    // log("begin to retry image from ${url}");

    final req = http.Request('GET', Uri.parse(url));
    if (headers != null) {
      req.headers.addAll(headers);
    }
    req.headers.addAll({"t": "$t", "sign": sign});
    final httpResponse = await _httpClient.send(req);

    return HttpGetResponse(httpResponse);
  }
}
