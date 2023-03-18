import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/client/dm_session.dart';
import 'package:nostrmo/component/name_component.dart';
import 'package:nostrmo/router/dm/dm_detail_item_component.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:pointycastle/export.dart' as pointycastle;

import '../../client/nip04/nip04.dart';
import '../../data/metadata.dart';
import '../../main.dart';
import '../../provider/metadata_provider.dart';

class DMDetailRouter extends StatefulWidget {
  DMDetailRouter();

  @override
  State<StatefulWidget> createState() {
    return _DMDetailRouter();
  }
}

class _DMDetailRouter extends State<DMDetailRouter> {
  DMSession? dmSession;
  @override
  Widget build(BuildContext context) {
    if (dmSession == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg == null) {
        RouterUtil.back(context);
        return Container();
      }
      dmSession = arg as DMSession?;
    }

    var nameComponnet = Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        return NameComponnet(
          pubkey: dmSession!.pubkey,
          metadata: metadata,
        );
      },
      selector: (context, _provider) {
        return _provider.getMetadata(dmSession!.pubkey);
      },
    );

    var localPubkey = nostr!.publicKey;

    var agreement = NIP04.getAgreement(nostr!.privateKey);

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(Icons.arrow_back_ios),
        ),
        title: nameComponnet,
      ),
      body: Container(
        width: double.maxFinite,
        child: ListView.builder(
          itemBuilder: (context, index) {
            var event = dmSession!.get(index);
            if (event == null) {
              return null;
            }

            return DMDetailItemComponent(
              sessionPubkey: dmSession!.pubkey,
              event: event,
              isLocal: localPubkey == event.pubKey,
              agreement: agreement,
            );
          },
          reverse: true,
          itemCount: dmSession!.length(),
          dragStartBehavior: DragStartBehavior.down,
        ),
      ),
    );
  }
}
