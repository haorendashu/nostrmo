import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/data/dm_session_info_db.dart';
import 'package:provider/provider.dart';
import 'package:pointycastle/export.dart' as pointycastle;

import '../../client/nip04/nip04.dart';
import '../../component/name_component.dart';
import '../../consts/base.dart';
import '../../data/dm_session_info.dart';
import '../../data/metadata.dart';
import '../../main.dart';
import '../../provider/dm_provider.dart';
import '../../provider/metadata_provider.dart';
import '../../util/router_util.dart';
import 'dm_detail_item_component.dart';

class DMDetailRouter extends StatefulWidget {
  DMDetailRouter();

  @override
  State<StatefulWidget> createState() {
    return _DMDetailRouter();
  }
}

class _DMDetailRouter extends CustState<DMDetailRouter> {
  DMSessionDetail? detail;

  @override
  Widget doBuild(BuildContext context) {
    if (detail == null) {
      var arg = RouterUtil.routerArgs(context);
      if (arg == null) {
        RouterUtil.back(context);
        return Container();
      }
      detail = arg as DMSessionDetail;
    }

    var nameComponnet = Selector<MetadataProvider, Metadata?>(
      builder: (context, metadata, child) {
        return NameComponnet(
          pubkey: detail!.dmSession.pubkey,
          metadata: metadata,
        );
      },
      selector: (context, _provider) {
        return _provider.getMetadata(detail!.dmSession.pubkey);
      },
    );

    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;

    var localPubkey = nostr!.publicKey;
    var agreement = NIP04.getAgreement(nostr!.privateKey);

    var maxWidth = MediaQuery.of(context).size.width;

    Widget main = Container(
      width: maxWidth,
      child: Column(children: [
        Expanded(
            child: ListView.builder(
          itemBuilder: (context, index) {
            var event = detail!.dmSession.get(index);
            if (event == null) {
              return null;
            }

            return DMDetailItemComponent(
              sessionPubkey: detail!.dmSession.pubkey,
              event: event,
              isLocal: localPubkey == event.pubKey,
              agreement: agreement,
            );
          },
          reverse: true,
          itemCount: detail!.dmSession.length(),
          dragStartBehavior: DragStartBehavior.down,
        )),
        GestureDetector(
          onTap: () {},
          child: Container(
            margin: EdgeInsets.only(
              left: Base.BASE_PADDING,
              top: Base.BASE_PADDING_HALF,
              right: Base.BASE_PADDING,
              bottom: Base.BASE_PADDING_HALF,
            ),
            height: 40,
            alignment: Alignment.center,
            // color: Colors.black,
            color: hintColor,
            child: Text(
              "Write a message",
              style: TextStyle(
                  // color: Colors.white,
                  ),
            ),
          ),
        ),
      ]),
    );

    if (detail!.info == null && detail!.dmSession.newestEvent != null) {
      main = Stack(
        children: [
          main,
          Positioned(
            child: GestureDetector(
              onTap: addDmSessionToKnown,
              child: Container(
                margin: EdgeInsets.all(Base.BASE_PADDING),
                height: 30,
                width: double.maxFinite,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    "Add to known list",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

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
      body: main,
    );
  }

  Future<void> addDmSessionToKnown() async {
    var _detail = await dmProvider.addDmSessionToKnown(detail!);
    setState(() {
      detail = _detail;
    });
  }

  @override
  Future<void> onReady(BuildContext context) async {
    if (detail != null &&
        detail!.info != null &&
        detail!.dmSession.newestEvent != null) {
      detail!.info!.readedTime = detail!.dmSession.newestEvent!.createdAt;
    }
  }
}
