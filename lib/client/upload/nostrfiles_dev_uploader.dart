import 'dart:io';

import 'package:dio/dio.dart';

class NostrfilesDevUploader {
  static var dio = Dio();

  static final String UPLOAD_ACTION = "https://nostrfiles.dev/upload_image";

  static Future<String?> upload(String filePath, {String? fileName}) async {
    var multipartFile =
        await MultipartFile.fromFile(filePath, filename: fileName);

    var formData = FormData.fromMap({"file": multipartFile});
    var response = await dio.post<String>(
      UPLOAD_ACTION,
      data: formData,
      options: Options(
        followRedirects: false,
        validateStatus: (status) {
          if (status == HttpStatus.movedTemporarily) {
            return true;
          }
          return false;
        },
      ),
    );

    if (response.statusCode == HttpStatus.movedTemporarily) {
      return response.headers.value("Location");
    }

    return null;
  }
}
