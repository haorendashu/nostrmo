import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'dart:convert' as convert;

Dio? _dio;
var cookieJar = CookieJar();

class DioUtil {
  static Dio getDio() {
    if (_dio == null) {
      _dio = Dio();
      if (_dio!.httpClientAdapter is IOHttpClientAdapter) {
        (_dio!.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
            (client) {
          client.badCertificateCallback = (cert, host, port) {
            return true;
          };
        };
      }

      // _dio!.options.connectTimeout = Duration(minutes: 1);
      // _dio!.options.receiveTimeout = Duration(minutes: 1);
      _dio!.options.headers["user-agent"] =
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36";
      _dio!.options.headers["accept-encoding"] = "gzip";
      CookieManager cookieManager = CookieManager(cookieJar);
      _dio!.interceptors.add(cookieManager);
    }
    return _dio!;
  }

  static setCookie(String link, String key, String value) {
    cookieJar.saveFromResponse(Uri.parse(link), [Cookie(key, value)]);
  }

  static Future<Map<String, dynamic>?> get(String link,
      [Map<String, dynamic>? queryParameters,
      Map<String, String>? header]) async {
    var dio = getDio();
    if (header != null) {
      dio.options.headers.addAll(header);
    }
    Response resp = await dio.get(link, queryParameters: queryParameters);
    if (resp.statusCode == 200) {
      if (resp.data is String) {
        return json.decode(resp.data);
      }
      return resp.data;
    } else {
      return null;
    }
  }

  static Future<String?> getStr(String link,
      [Map<String, dynamic>? queryParameters,
      Map<String, String>? header]) async {
    var dio = getDio();
    if (header != null) {
      dio.options.headers.addAll(header);
    }
    Response resp =
        await dio.get<String>(link, queryParameters: queryParameters);
    if (resp.statusCode == 200) {
      return resp.data;
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>> post(
      String link, Map<String, dynamic> parameters,
      [Map<String, String>? header]) async {
    var dio = getDio();
    if (header != null) {
      dio.options.headers.addAll(header);
    }
    Response resp = await dio.post(link, data: parameters);
    return resp.data;
  }

  static Future<Uint8List?> downloadFileAsBytes(
    String url, {
    Function(int, int)? onProgress,
  }) async {
    final dio = Dio();

    try {
      final response = await dio.get(
        url,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received, total);
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Uint8List) {
        return response.data;
      } else {
        print('Download fail statusCode: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (e is DioException) {
        print('Network fail: ${e.message}');
        return null;
      } else {
        print('Doanload fail: ${e.toString()}');
        return null;
      }
    }
  }
}
