import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/upload/nip95_uploader.dart';
import 'package:nostrmo/client/upload/nip96_uploader.dart';
import 'package:nostrmo/client/upload/void_cat.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:nostrmo/util/store_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../consts/base64.dart';
import '../../consts/image_services.dart';
import 'nostr_build_uploader.dart';
import 'nostrfiles_dev_uploader.dart';
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

  static Future<Event?> pickAndUpload2NIP95(BuildContext context) async {
    var filePath = await pick(context);
    if (StringUtil.isNotBlank(filePath)) {
      return NIP95Uploader.uploadForEvent(filePath!);
    }

    return null;
  }

  static Future<void> pickAndUpload(BuildContext context) async {
    var filePath = await pick(context);
    if (StringUtil.isNotBlank(filePath)) {
      // var result = await Pomf2LainLa.upload(filePath!);
      var result =
          await NIP96Uploader.upload("https://nostr.build/", filePath!);
      print("result $result");
    }
  }

  static Future<String?> pick(BuildContext context) async {
    if (PlatformUtil.isPC() || PlatformUtil.isWeb()) {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        if (PlatformUtil.isWeb() && result.files.single.bytes != null) {
          return BASE64.toBase64(result.files.single.bytes!);
        }

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

      if (settingProvider.imgCompress >= 30 &&
          settingProvider.imgCompress < 100) {
        var fileExtension = StoreUtil.getFileExtension(file!.path);
        fileExtension ??= "jpg";
        var tempDir = await getTemporaryDirectory();
        var tempFilePath =
            "${tempDir.path}/${StringUtil.rndNameStr(12)}$fileExtension";
        var result = await FlutterImageCompress.compressAndGetFile(
          file.path,
          tempFilePath,
          quality: settingProvider.imgCompress,
        );

        if (result != null) {
          // log("file ${result.path} length ${await result.length()}");
          return result.path;
        }
      }

      return file!.path;
    }

    return null;
  }

  static Future<String?> upload(String localPath,
      {String? imageService, String? fileName}) async {
    // if (imageService == ImageServices.NOSTRIMG_COM) {
    //   return await NostrimgComUploader.upload(localPath);
    // } else if (imageService == ImageServices.VOID_CAT) {
    //   return await VoidCatUploader.upload(localPath);
    // } else if (imageService == ImageServices.NOSTRFILES_DEV) {
    //   return await NostrfilesDevUploader.upload(localPath);
    // } else
    if (imageService == ImageServices.POMF2_LAIN_LA) {
      return await Pomf2LainLa.upload(localPath, fileName: fileName);
    } else if (imageService == ImageServices.NOSTR_BUILD) {
      return await NostrBuildUploader.upload(localPath, fileName: fileName);
    } else if (imageService == ImageServices.NIP_95) {
      return await NIP95Uploader.upload(localPath, fileName: fileName);
    } else if (imageService == ImageServices.NIP_96 &&
        StringUtil.isNotBlank(settingProvider.imageServiceAddr)) {
      return await NIP96Uploader.upload(
          settingProvider.imageServiceAddr!, localPath,
          fileName: fileName);
    }
    return await NostrBuildUploader.upload(localPath, fileName: fileName);
  }
}
