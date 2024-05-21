import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

import '../../consts/base64.dart';
import '../../main.dart';
import '../../util/hash_util.dart';
import '../../util/string_util.dart';
import '../event.dart';
import '../event_kind.dart';

// This uploader not complete.
class BolssomUploader {
  static var dio = Dio();

  static Future<String?> upload(String endPoint, String filePath,
      {String? fileName}) async {
    var uri = Uri.tryParse(endPoint);
    if (uri == null) {
      return null;
    }
    var uploadApiPath = Uri(
            scheme: uri.scheme,
            userInfo: uri.userInfo,
            host: uri.host,
            port: uri.port,
            path: "/upload")
        .toString();
    // log("uploadApiPath is $uploadApiPath");

    String? payload;
    MultipartFile? multipartFile;
    Uint8List? bytes;
    if (BASE64.check(filePath)) {
      bytes = BASE64.toData(filePath);
    } else {
      var file = File(filePath);
      bytes = file.readAsBytesSync();

      if (StringUtil.isBlank(fileName)) {
        fileName = filePath.split("/").last;
      }
    }

    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    var fileSize = bytes.length;
    // log("file size is ${bytes.length}");
    payload = HashUtil.sha256Bytes(bytes);
    multipartFile = MultipartFile.fromBytes(
      bytes,
      filename: fileName,
    );

    Map<String, String>? headers = {};
    if (StringUtil.isNotBlank(fileName)) {
      var mt = lookupMimeType(fileName!);
      if (StringUtil.isNotBlank(mt)) {
        headers["Content-Type"] = mt!;
      }
    }
    if (StringUtil.isBlank(headers["Content-Type"])) {
      if (multipartFile.contentType != null) {
        headers["Content-Type"] = multipartFile.contentType!.mimeType;
      } else {
        headers["Content-Type"] = "multipart/form-data";
      }
    }

    var tags = [];
    tags.add(["t", "upload"]);
    tags.add([
      "expiration",
      ((DateTime.now().millisecondsSinceEpoch ~/ 1000) + 60 * 10).toString()
    ]);
    tags.add(["size", "$fileSize"]);
    tags.add(["x", payload]);
    var nip98Event =
        Event(nostr!.publicKey, EventKind.HTTP_AUTH, tags, "Upload $fileName");
    nostr!.signEvent(nip98Event);
    // log(jsonEncode(nip98Event.toJson()));
    headers["Authorization"] =
        "Nostr ${base64Url.encode(utf8.encode(jsonEncode(nip98Event.toJson())))}";

    // log(jsonEncode(headers));

    var formData = FormData.fromMap({"file": multipartFile});
    try {
      var response = await dio.put(
        uploadApiPath,
        // data: formData,
        data: Stream.fromIterable(bytes.map((e) => [e])),
        options: Options(
          headers: headers,
          validateStatus: (status) {
            return true;
          },
        ),
      );
      var body = response.data;
      // log(jsonEncode(response.data));
      if (body is Map<String, dynamic> &&
          body["status"] == "success" &&
          body["nip94_event"] != null) {
        var nip94Event = body["nip94_event"];
        if (nip94Event["tags"] != null) {
          for (var tag in nip94Event["tags"]) {
            if (tag is List && tag.length > 1) {
              var k = tag[0];
              var v = tag[1];

              if (k == "url") {
                return v;
              }
            }
          }
        }
      }
    } catch (e) {
      print("nostr.build nip96 upload exception:");
      print(e);
    }

    return null;
  }
}
