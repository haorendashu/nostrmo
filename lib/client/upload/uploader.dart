import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'nostr_build_uploader.dart';

class Uploader {
  static Future<String?> pickAndUpload(BuildContext context) async {
    var assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(maxAssets: 1),
    );

    if (assets != null && assets.isNotEmpty) {
      for (var asset in assets) {
        var file = await asset.file;
        return await NostrBuildUploader.upload(file!.path);
      }
    }

    return null;
  }
}
