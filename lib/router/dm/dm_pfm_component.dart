import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/nip17/pfm_algorithm_decrypt.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/util/dio_util.dart';

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

    return Image.memory(imageData!);
  }

  @override
  Future<void> onReady(BuildContext context) async {
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
