import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/src/web/file_service.dart';
import 'package:http/http.dart' as http;
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/hash_util.dart';

import '../../consts/base64.dart';
import 'data_file_response.dart';

class RetryHttpFileServcie extends FileService {
  final http.Client _httpClient;

  RetryHttpFileServcie({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String>? headers}) async {
    url = url.trim();
    // log("begin to load image from ${url}");
    try {
      if (BASE64.check(url)) {
        return DataFileResponse(BASE64.toData(url));
      }

      var req = http.Request('GET', Uri.parse(url));
      if (headers != null) {
        req.headers.addAll(headers);
      }
      var httpResponse = await _httpClient.send(req);
      if (PlatformUtil.isWeb() && httpResponse.statusCode == 301) {
        var location = httpResponse.headers["Location"];
        if (StringUtil.isNotBlank(location)) {
          url = location!;
          var req = http.Request('GET', Uri.parse(url));
          if (headers != null) {
            req.headers.addAll(headers);
          }
          httpResponse = await _httpClient.send(req);
        }
      }

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
