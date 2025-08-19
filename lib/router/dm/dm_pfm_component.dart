import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/nip17/pfm_algorithm_decrypt.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/util/dio_util.dart';

import '../../component/image_preview_dialog.dart';
import '../../generated/l10n.dart';

class DMPfmComponent extends StatefulWidget {
  Event event;

  DMPfmComponent({
    super.key,
    required this.event,
  });

  @override
  State<DMPfmComponent> createState() => _DMPfmComponentState();
}

class _DMPfmComponentState extends CustState<DMPfmComponent> {
  Uint8List? imageData;

  @override
  Widget doBuild(BuildContext context) {
    if (imageData == null) {
      return Container();
    }

    return GestureDetector(
      onTap: () {
        if (imageData != null) {
          List<ImageProvider> imageProviders = [];
          imageProviders.add(MemoryImage(imageData!));

          MultiImageProvider multiImageProvider =
              MultiImageProvider(imageProviders, initialIndex: 0);

          ImagePreviewDialog.show(context, multiImageProvider);
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Image.memory(imageData!),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    log(jsonEncode(widget.event.toJson()));
    var event = widget.event;
    var pfmAlgorithm = PfmAlgorithmDecrypt.getFromEvent(event);
    if (pfmAlgorithm != null) {
      var data = await DioUtil.downloadFileAsBytes(event.content);
      if (data != null) {
        var decryptedData = await pfmAlgorithm.decrypt(data);
        setState(() {
          imageData = decryptedData;
        });
      }
    }
  }
}
