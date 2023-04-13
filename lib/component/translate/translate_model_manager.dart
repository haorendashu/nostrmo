import 'dart:developer';

import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslateModelManager {
  static TranslateModelManager? _manager;

  static TranslateModelManager getInstance() {
    if (_manager == null) {
      _manager = TranslateModelManager();
      _manager!._init();
    }
    return _manager!;
  }

  OnDeviceTranslatorModelManager? modelManager;

  void _init() {
    modelManager = OnDeviceTranslatorModelManager();
  }

  Future<void> checkAndDownloadAllModel() async {
    for (var lan in TranslateLanguage.values) {
      var bcpCode = lan.bcpCode;
      if (!await modelManager!.isModelDownloaded(bcpCode)) {
        log("begin to download model $bcpCode");
        await modelManager!.downloadModel(bcpCode);
      } else {
        log("model $bcpCode had bean downloaded");
      }
    }
  }

  Future<void> checkAndDownloadTargetModel(List<String> bcpCodes) async {
    for (var bcpCode in bcpCodes) {
      if (!await modelManager!.isModelDownloaded(bcpCode)) {
        log("begin to download model $bcpCode");
        await modelManager!.downloadModel(bcpCode);
      } else {
        log("model $bcpCode had bean downloaded");
      }
    }
  }
}
