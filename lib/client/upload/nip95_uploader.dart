import 'package:mime/mime.dart';
import 'package:nostrmo/client/event.dart';
import 'package:nostrmo/client/event_kind.dart';
import 'package:nostrmo/client/nip19/nip19_tlv.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/string_util.dart';
import 'dart:io';

import '../../component/content/content_decoder.dart';
import '../../consts/base64.dart';

class NIP95Uploader {
  static Future<String?> upload(String filePath, {String? fileName}) async {
    var result = await uploadForEvent(filePath, fileName: fileName);
    if (result != null) {
      // TODO Here should set relayAddrs to event.
      return NIP19Tlv.encodeNevent(
          Nevent(id: result.id, relays: result.sources));
    }

    return null;
  }

  static Future<Event?> uploadForEvent(String filePath,
      {String? fileName}) async {
    String? base64Content;
    if (BASE64.check(filePath)) {
      base64Content = filePath;
    } else {
      var file = File(filePath);
      var data = await file.readAsBytes();
      base64Content = BASE64.toBase64(data);
    }

    if (StringUtil.isNotBlank(base64Content)) {
      base64Content = base64Content.replaceFirst("data:image/png;base64,", "");
    }

    var mimeType = lookupMimeType(filePath);
    if (StringUtil.isNotBlank(mimeType)) {
      var pathType = ContentDecoder.getPathType(filePath);
      if (pathType == "image") {
        mimeType = "image/jpeg";
      } else if (pathType == "video") {
        mimeType = "video/mp4";
      } else if (pathType == "audio") {
        mimeType = "audio/mpeg";
      }
    }

    var tags = [
      ["type", mimeType],
      ["alt", "Binary data"],
    ];

    var pubkey = nostr!.publicKey;
    var event =
        Event(pubkey, EventKind.STORAGE_SHARED_FILE, tags, base64Content);

    return nostr!.sendEvent(event);
  }
}
