import 'package:flutter/material.dart';
import 'package:nostrmo/client/nip04/nip04.dart';
import 'package:nostrmo/data/event_db.dart';

import '../../client/event.dart';
import '../../main.dart';
import '../../util/string_util.dart';

mixin DMPlaintextHandle<T extends StatefulWidget> on State<T> {
  String? currentPlainEventId;

  String? plainContent;

  void handleEncryptedText(Event event, String pubkey) {
    if (NIP04.isEncrypted(event.content)) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        var pc = await nostr!.nostrSigner.decrypt(pubkey, event.content);
        if (StringUtil.isNotBlank(pc)) {
          // save to db, avoid decrypt all the time
          try {
            event.content = pc!;
            EventDB.update(settingProvider.privateKeyIndex!, event);
          } catch (e, st) {
            print(e);
            print(st.toString());
          }

          setState(() {
            plainContent = pc;
            currentPlainEventId = event.id;
          });
        }
      });
    }
  }
}
