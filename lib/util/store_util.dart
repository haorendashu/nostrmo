import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/util/hash_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class StoreUtil {
  String? _basePath;

  static StoreUtil? _storeUtil;

  static Future<StoreUtil> getInstance() async {
    if (_storeUtil == null) {
      _storeUtil = StoreUtil();
      Directory appDocDir = await getApplicationDocumentsDirectory();
      _storeUtil!._basePath = appDocDir.path;
    }
    return _storeUtil!;
  }

  static Future<String> getBasePath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir.path;
  }

  static Future<String?> saveFileToDocument(String filePath,
      {String? targetFileName}) async {
    if (StringUtil.isBlank(targetFileName)) {
      var fileName = basename(filePath);
      var fileNameStrs = fileName.split(".");
      if (fileNameStrs.length > 1) {
        fileName =
            "${DateTime.now().millisecondsSinceEpoch}.${fileNameStrs[1]}";
      }

      targetFileName = fileName;
    }

    var oldFile = File(filePath);

    var basePath = await getBasePath();
    var targetFilePath = "$basePath/$targetFileName";
    var targetFile = File(targetFilePath);
    if (targetFile.existsSync()) {
      targetFile.deleteSync();
    }

    await oldFile.copy(targetFilePath);
    return targetFilePath;
  }

  static Future<String> saveBS2TempFile(String extension, List<int> uint8list,
      {String? randFolderName, String? filename}) async {
    var tempDir = await getTemporaryDirectory();
    var folderPath = tempDir.path;
    if (StringUtil.isNotBlank(randFolderName)) {
      folderPath = folderPath + "/" + randFolderName!;
      checkAndCreateDir(folderPath + "/");
    }
    var tempFilePath =
        folderPath + "/" + StringUtil.rndNameStr(12) + "." + extension;
    if (StringUtil.isNotBlank(filename)) {
      tempFilePath = folderPath + "/" + filename! + "." + extension;
    }

    var tempFile = File(tempFilePath);
    await tempFile.writeAsBytes(uint8list);

    return tempFilePath;
  }

  static Future<String> saveBS2TempFileByMd5(
      String extension, List<int> uint8list,
      {String? randFolderName, String? filename}) async {
    var md5Hash = HashUtil.md5Bytes(uint8list);

    var tempDir = await getTemporaryDirectory();
    var folderPath = tempDir.path;
    var tempFilePath = folderPath + "/" + md5Hash + "." + extension;

    var tempFile = File(tempFilePath);
    if (!tempFile.existsSync()) {
      await tempFile.writeAsBytes(uint8list);
    }

    return tempFilePath;
  }

  static Future<void> save2File(String filepath, List<int> uint8list) async {
    var tempFile = File(filepath);
    await tempFile.writeAsBytes(uint8list);
  }

  static String bytesToShowStr(int bytesLength) {
    double bl = bytesLength.toDouble();
    if (bl < 1024) {
      return bl.toString() + " B";
    }

    bl = bl / 1024;
    if (bl < 1024) {
      return bl.toStringAsFixed(2) + " KB";
    }

    bl = bl / 1024;
    if (bl < 1024) {
      return bl.toStringAsFixed(2) + " MB";
    }

    bl = bl / 1024;
    if (bl < 1024) {
      return bl.toStringAsFixed(2) + " GB";
    }

    return "";
  }

  static void checkAndCreateDir(String dirPath) {
    var dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync();
    }
  }

  static bool checkDir(String dirPath) {
    var dir = Directory(dirPath);
    return dir.existsSync();
  }

  static String? getFileExtension(String path) {
    var index = path.lastIndexOf(".");
    if (index == -1) {
      return null;
    }

    var n = path.substring(index);
    n = n.toLowerCase();

    var strs = n.split("?");
    return strs[0];
  }

  static String? getfileType(String path) {
    var s = getFileExtension(path);

    if (s == ".png" ||
        s == ".jpg" ||
        s == ".jpeg" ||
        s == ".gif" ||
        s == ".webp") {
      return "image";
    } else if (s == ".mp4" || s == ".mov" || s == ".wmv") {
      return "video";
    } else {
      return null;
    }
  }

  static Future saveBS2Gallery(String extension, Uint8List uint8list) async {
    var tempPath = await StoreUtil.saveBS2TempFile(extension, uint8list);
    return await ImageGallerySaver.saveFile(tempPath);
  }

  static int? getFileSize(String filepath) {
    var file = File(filepath);
    return file.lengthSync();
  }
}
