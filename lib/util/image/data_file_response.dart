import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/src/web/file_service.dart';

class DataFileResponse implements FileServiceResponse {
  Uint8List data;

  DataFileResponse(this.data);

  final DateTime _receivedTime = DateTime.now();

  @override
  int get statusCode => HttpStatus.ok;

  String? _header(String name) {
    return null;
  }

  @override
  Stream<List<int>> get content {
    return Stream.value(data.toList());
  }

  @override
  int? get contentLength => data.length;

  @override
  DateTime get validTill {
    var ageDuration = const Duration(days: 7);
    return _receivedTime.add(ageDuration);
  }

  @override
  String? get eTag => _header(HttpHeaders.etagHeader);

  @override
  String get fileExtension {
    // TODO this is not the real extension
    return "jpeg";
  }
}
