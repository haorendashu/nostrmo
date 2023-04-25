import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:nostrmo/client/upload/void_cat.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../consts/image_services.dart';
import 'nostr_build_uploader.dart';
import 'nostrimg_com_uploader.dart';
import 'pomf2_lain_la.dart';

class Uploader {
  // static Future<String?> pickAndUpload(BuildContext context) async {
  //   var assets = await AssetPicker.pickAssets(
  //     context,
  //     pickerConfig: const AssetPickerConfig(maxAssets: 1),
  //   );

  //   if (assets != null && assets.isNotEmpty) {
  //     for (var asset in assets) {
  //       var file = await asset.file;
  //       return await NostrBuildUploader.upload(file!.path);
  //     }
  //   }

  //   return null;
  // }

  static String getFileType(String filePath) {
    var fileType = lookupMimeType(filePath);
    if (StringUtil.isBlank(fileType)) {
      fileType = "image/jpeg";
    }

    return fileType!;
  }

  static Future<void> pickAndUpload(BuildContext context) async {
    var filePath = await pick(context);
    if (StringUtil.isNotBlank(filePath)) {
      var result = await Pomf2LainLa.upload(filePath!);
      print("result $result");
    }
  }

  static Future<String?> pick(BuildContext context) async {
    if (PlatformUtil.isPC()) {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        return result.files.single.path;
      }

      return null;
    }
    var assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(maxAssets: 1),
    );

    if (assets != null && assets.isNotEmpty) {
      var file = await assets[0].file;
      return file!.path;
    }

    return null;
  }

  static Future<String?> upload(String localPath,
      {String? imageService}) async {
    if (imageService == ImageServices.NOSTR_BUILD) {
      return await NostrBuildUploader.upload(localPath);
    } else if (imageService == ImageServices.NOSTRIMG_COM) {
      return await NostrimgComUploader.upload(localPath);
    } else if (imageService == ImageServices.POMF2_LAIN_LA) {
      return await Pomf2LainLa.upload(localPath);
    } else if (imageService == ImageServices.VOID_CAT) {
      return await VoidCatUploader.upload(localPath);
    }
    return await NostrBuildUploader.upload(localPath);
  }
}
