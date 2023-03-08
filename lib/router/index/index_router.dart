import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/cust_nostr.dart';
import 'package:nostrmo/client/cust_relay.dart';
import 'package:nostrmo/client/filter.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/dm/dm_router.dart';
import 'package:nostrmo/router/follow/follow_router.dart';
import 'package:nostrmo/router/notice/notice_router.dart';
import 'package:nostrmo/router/search/search_router.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:provider/provider.dart';

import '../../data/relay_status.dart';
import '../../provider/index_provider.dart';
import '../login/login_router.dart';
import 'index_bottom_bar.dart';

class IndexRouter extends StatefulWidget {
  Function reload;

  IndexRouter({required this.reload});

  @override
  State<StatefulWidget> createState() {
    return _IndexRouter();
  }
}

class _IndexRouter extends State<IndexRouter> {
  // ECPrivateKey getPrivateKey(String privateKey) {
  //   var d0 = BigInt.parse(privateKey, radix: 16);
  //   return ECPrivateKey(d0, secp256k1);
  // }

  // var secp256k1 = ECDomainParameters("secp256k1");

  // String keyToString(BigInt d0) {
  //   ECPoint P = (secp256k1.G * d0)!;
  //   return P.x!.toBigInteger()!.toRadixString(16).padLeft(64, "0");
  // }

  @override
  Widget build(BuildContext context) {
    // if (nostr == null) {
    //   return LoginRouter();
    // }
    var _indexProvider = Provider.of<IndexProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
              child: IndexedStack(
            children: [
              FollowRouter(),
              DMRouter(),
              SearchRouter(),
              NoticeRouter(),
            ],
            index: _indexProvider.currentTap,
          )),
          IndexBottomBar(),
        ],
      ),
    );

    // return Scaffold(
    //   floatingActionButton: IconButton(
    //     icon: Icon(Icons.add),
    //     onPressed: () async {
    //       var relayStatus = RelayStatus("wss://nos.lol");
    //       var relay = Relay(
    //         relayStatus.addr,
    //         access: WriteAccess.readWrite,
    //       );
    //       var custRelay = CustRelay(relay, relayStatus);

    //       var pk = generatePrivateKey();
    //       CustNostr nostr = CustNostr(privateKey: pk);
    //       await nostr.pool.add(custRelay);

    //       var filter = Filter(kinds: [EventKind.metaData], limit: 100);
    //       nostr.pool.subscribe([filter.toJson()], (event) {
    //         print(event.toJson());
    //       });

    //       // RouterUtil.router(context, RouterPath.EDITOR);

    //       // ECPrivateKey ecPrivateKey1 = getPrivateKey(
    //       //     "3239d943acb5c5a7e0f1695e5897dcaa62d08d7b6c70ae55c9ddc24d03646dca");
    //       // var agreement1 = ECDHBasicAgreement();
    //       // agreement1.init(ecPrivateKey1);
    //       // ECPublicKey ecPublicKey1 =
    //       //     ECPublicKey(secp256k1.G * ecPrivateKey1.d, secp256k1);

    //       // ECPrivateKey ecPrivateKey2 = getPrivateKey(
    //       //     "b5d906cbadc73f5b4ec2eadc80ed5712bf30ac2172e1001ce4bb5d58204fc848");
    //       // var agreement2 = ECDHBasicAgreement();
    //       // agreement2.init(ecPrivateKey2);
    //       // ECPublicKey ecPublicKey2 =
    //       //     ECPublicKey(secp256k1.G * ecPrivateKey2.d, secp256k1);

    //       // // var result1 = agreement1.calculateAgreement(ecPublicKey2);
    //       // // print(result1.toRadixString(16).padLeft(64, "0"));

    //       // // var result2 = agreement2.calculateAgreement(ecPublicKey1);
    //       // // print(result2.toRadixString(16).padLeft(64, "0"));

    //       // var result = NIP04.encrypt("hellp", agreement1,
    //       //     "b49582509fedf4bf46f02c98f43319e5f89bdbc63ca5464d7032bd833013398e");
    //       // print(result);

    //       // result = NIP04.decrypt(result, agreement2,
    //       //     "91c115843814ff5fa37c643097c32a3a39aac797d8b530acce405c3e79f030d2");
    //       // print(result);
    //     },
    //   ),
    // );
  }
}
