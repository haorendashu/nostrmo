import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

import 'package:nostrmo/client/upload/uploader.dart';
import 'package:nostrmo/util/store_util.dart';
import 'package:nostrmo/util/string_util.dart';

import 'nostr_build_uploader.dart';

class VoidCatUploader {
  static final String UPLOAD_ACTION = "https://void.cat/upload?cli=true";

  static Future<String?> upload(String filePath, {String? fileName}) async {
    var tempFile = File(filePath);
    var bytes = await tempFile.readAsBytes();
    var digest = sha256.convert(bytes);
    var fileHex = hex.encode(digest.bytes);

    Map<String, dynamic> headers = {};
    headers["content-type"] = "application/octet-stream";
    headers["v-full-digest"] = fileHex;

    var fileType = Uploader.getFileType(filePath);
    headers["v-content-type"] = fileType;
    if (StringUtil.isNotBlank(fileName)) {
      headers["V-Filename"] = fileName;
    }

    var response = await NostrBuildUploader.dio.post<String>(
      UPLOAD_ACTION,
      data: Stream.fromIterable(bytes.map((e) => [e])),
      options: Options(
        headers: headers,
      ),
    );
    var body = response.data;

    return body;
  }
}
