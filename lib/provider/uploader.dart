import 'package:bot_toast/bot_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/upload/blossom_uploader.dart';
import 'package:nostr_sdk/upload/nip95_uploader.dart';
import 'package:nostr_sdk/upload/nip96_uploader.dart';
import 'package:nostr_sdk/upload/nostr_build_uploader.dart';
import 'package:nostr_sdk/upload/pomf2_lain_la.dart';
import 'package:nostr_sdk/upload/void_cat.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

import '../consts/base64.dart';
import '../consts/image_services.dart';
import '../generated/l10n.dart';
import '../main.dart';
import '../util/store_util.dart';

class Uploader {
  static int NIP95_MAX_LENGTH = 80000;

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

  static Future<Event?> pickAndUpload2NIP95(BuildContext context) async {
    var filePath = await pick(context);
    if (StringUtil.isNotBlank(filePath)) {
      return NIP95Uploader.uploadForEvent(nostr!, filePath!);
    }

    return null;
  }

  static Future<void> pickAndUpload(BuildContext context) async {
    var filePath = await pick(context);
    if (StringUtil.isNotBlank(filePath)) {
      // var result = await Pomf2LainLa.upload(filePath!);
      var result =
          await NIP96Uploader.upload(nostr!, "https://nostr.build/", filePath!);
      print("result $result");
    }
  }

  static Future<String?> pick(BuildContext context) async {
    if (PlatformUtil.isPC() || PlatformUtil.isWeb()) {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        if (settingProvider.imageService == ImageServices.NIP_95 &&
            result.files.single.size > NIP95_MAX_LENGTH) {
          BotToast.showText(text: S.of(context).File_is_too_big_for_NIP_95);
        }

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
      useRootNavigator: false,
    );

    if (assets != null && assets.isNotEmpty) {
      var file = await assets[0].file;

      if (settingProvider.imgCompress >= 30 &&
          settingProvider.imgCompress < 100) {
        var fileExtension = StoreUtil.getFileExtension(file!.path);
        fileExtension ??= ".jpg";
        var tempDir = await getTemporaryDirectory();
        var tempFilePath =
            "${tempDir.path}/${StringUtil.rndNameStr(12)}$fileExtension";
        FlutterImageCompress.validator.ignoreCheckExtName = true;
        var result = await FlutterImageCompress.compressAndGetFile(
          file.path,
          tempFilePath,
          quality: settingProvider.imgCompress,
        );

        if (result != null) {
          if (settingProvider.imageService == ImageServices.NIP_95 &&
              (await result.length()) > NIP95_MAX_LENGTH) {
            BotToast.showText(text: S.of(context).File_is_too_big_for_NIP_95);
          }

          // log("file ${result.path} length ${await result.length()}");
          return result.path;
        }
      }

      if (settingProvider.imageService == ImageServices.NIP_95) {
        var fileSize = StoreUtil.getFileSize(file!.path);
        if (fileSize != null && fileSize > NIP95_MAX_LENGTH) {
          BotToast.showText(text: S.of(context).File_is_too_big_for_NIP_95);
        }
      }

      return file!.path;
    }

    return null;
  }

  static Future<List<String>> pickFiles(BuildContext context) async {
    List<String> resultFiles = [];

    if (PlatformUtil.isPC() || PlatformUtil.isWeb()) {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(allowMultiple: true);

      if (result != null) {
        for (var file in result.files) {
          var size = file.size;
          if (settingProvider.imageService == ImageServices.NIP_95 &&
              size > NIP95_MAX_LENGTH) {
            BotToast.showText(text: S.of(context).File_is_too_big_for_NIP_95);
            return [];
          }

          if (PlatformUtil.isWeb() && file.bytes != null) {
            resultFiles.add(BASE64.toBase64(result.files.single.bytes!));
          } else if (StringUtil.isNotBlank(file.path)) {
            resultFiles.add(file.path!);
          }
        }
      }

      return resultFiles;
    }

    var assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(maxAssets: 20),
      useRootNavigator: false,
    );

    if (assets != null && assets.isNotEmpty) {
      for (var asset in assets) {
        var file = await asset.file;

        if (settingProvider.imgCompress >= 30 &&
            settingProvider.imgCompress < 100) {
          var fileExtension = StoreUtil.getFileExtension(file!.path);
          fileExtension ??= ".jpg";
          var tempDir = await getTemporaryDirectory();
          var tempFilePath =
              "${tempDir.path}/${StringUtil.rndNameStr(12)}$fileExtension";
          FlutterImageCompress.validator.ignoreCheckExtName = true;
          var result = await FlutterImageCompress.compressAndGetFile(
            file.path,
            tempFilePath,
            quality: settingProvider.imgCompress,
          );

          if (result != null) {
            if (settingProvider.imageService == ImageServices.NIP_95 &&
                (await result.length()) > NIP95_MAX_LENGTH) {
              BotToast.showText(text: S.of(context).File_is_too_big_for_NIP_95);
              return [];
            }

            resultFiles.add(result.path);
            continue;
          }
        }

        if (settingProvider.imageService == ImageServices.NIP_95) {
          var fileSize = StoreUtil.getFileSize(file!.path);
          if (fileSize != null && fileSize > NIP95_MAX_LENGTH) {
            BotToast.showText(text: S.of(context).File_is_too_big_for_NIP_95);
            return [];
          }
        }

        resultFiles.add(file!.path);
      }
    }

    return resultFiles;
  }

  static Future<String?> upload(String localPath,
      {String? imageService, String? fileName}) async {
    // if (imageService == ImageServices.NOSTRIMG_COM) {
    //   return await NostrimgComUploader.upload(localPath);
    // } else  if (imageService == ImageServices.NOSTRFILES_DEV) {
    //   return await NostrfilesDevUploader.upload(localPath);
    // } else
    if (imageService == ImageServices.POMF2_LAIN_LA) {
      return await Pomf2LainLa.upload(localPath, fileName: fileName);
    } else if (imageService == ImageServices.NOSTR_BUILD) {
      // return await NostrBuildUploader.upload(localPath, fileName: fileName);
      return await NIP96Uploader.upload(
          nostr!, "https://nostr.build/", localPath,
          fileName: fileName);
    } else if (imageService == ImageServices.NOSTO_RE) {
      return await BolssomUploader.upload(
          nostr!, "https://nosto.re/", localPath,
          fileName: fileName);
    } else if (imageService == ImageServices.NIP_95) {
      return await NIP95Uploader.upload(nostr!, localPath, fileName: fileName);
    } else if (imageService == ImageServices.NIP_96 &&
        StringUtil.isNotBlank(settingProvider.imageServiceAddr)) {
      return await NIP96Uploader.upload(
          nostr!, settingProvider.imageServiceAddr!, localPath,
          fileName: fileName);
    } else if (imageService == ImageServices.BLOSSOM &&
        StringUtil.isNotBlank(settingProvider.imageServiceAddr)) {
      return await BolssomUploader.upload(
          nostr!, settingProvider.imageServiceAddr!, localPath,
          fileName: fileName);
    } else if (imageService == ImageServices.VOID_CAT) {
      return await VoidCatUploader.upload(localPath);
    }
    if (PlatformUtil.isWeb()) {
      return await BolssomUploader.upload(
          nostr!, "https://nosto.re/", localPath,
          fileName: fileName);
    }
    // return await NostrBuildUploader.upload(localPath, fileName: fileName);
    return await NIP96Uploader.upload(nostr!, "https://nostr.build/", localPath,
        fileName: fileName);
  }
}
