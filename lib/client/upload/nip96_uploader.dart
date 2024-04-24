import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/client/nip96/nip96_info_loader.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/hash_util.dart';
import 'package:nostrmo/util/string_util.dart';

import '../../consts/base64.dart';

class NIP96Uploader {
  static var dio = Dio();

  static Future<String?> upload(String serverUrl, String filePath,
      {String? fileName}) async {
    var sa = await NIP96InfoLoader.getInstance().getServerAdaptation(serverUrl);
    if (sa == null || StringUtil.isBlank(sa.apiUrl)) {
      return null;
    }
    // log(jsonEncode(sa.toJson()));

    bool isNip98Required = false;
    if (sa.plans != null &&
        sa.plans != null &&
        sa.plans!.free != null &&
        sa.plans!.free!.isNip98Required != null) {
      isNip98Required = sa.plans!.free!.isNip98Required!;
    }

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

    if (isNip98Required) {
      var tags = [];
      tags.add(["u", sa.apiUrl]);
      tags.add(["method", "POST"]);
      if (StringUtil.isNotBlank(payload)) {
        tags.add(["payload", payload]);
      }
      var nip98Event = Event(nostr!.publicKey, EventKind.HTTP_AUTH, tags, "");

      nostr!.signEvent(nip98Event);
      // log(jsonEncode(nip98Event.toJson()));
      headers["Authorization"] =
          "Nostr ${base64Url.encode(utf8.encode(jsonEncode(nip98Event.toJson())))}";

      // log(jsonEncode(headers));
    }

    var formData = FormData.fromMap({"file": multipartFile});
    try {
      var response = await dio.post(sa.apiUrl!,
          data: formData,
          options: Options(
            headers: headers,
          ));
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
