import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nostrmo/client/dm_session.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/editor/editor_mixin.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/dm_session_info_db.dart';
import 'package:nostrmo/router/edit/editor_router.dart';
import 'package:nostrmo/router/index/index_app_bar.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:provider/provider.dart';
import 'package:pointycastle/export.dart' as pointycastle;
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../client/nip04/nip04.dart';
import '../../component/editor/lnbc_embed_builder.dart';
import '../../component/editor/mention_event_embed_builder.dart';
import '../../component/editor/mention_user_embed_builder.dart';
import '../../component/editor/pic_embed_builder.dart';
import '../../component/editor/tag_embed_builder.dart';
import '../../component/editor/video_embed_builder.dart';
import '../../component/name_component.dart';
import '../../consts/base.dart';
import '../../data/dm_session_info.dart';
import '../../data/metadata.dart';
import '../../generated/l10n.dart';
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

class _DMDetailRouter extends CustState<DMDetailRouter> with EditorMixin {
  DMSessionDetail? detail;

  ECDHBasicAgreement? agreement;

  @override
  void initState() {
    super.initState();
    handleFocusInit();
  }

  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);
    var textColor = themeData.textTheme.bodyMedium!.color;
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;

    var hintColor = themeData.hintColor;
    var s = S.of(context);

    var arg = RouterUtil.routerArgs(context);
    if (arg == null) {
      RouterUtil.back(context);
      return Container();
    }
    detail = arg as DMSessionDetail;

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

    var localPubkey = nostr!.publicKey;
    agreement = NIP04.getAgreement(nostr!.privateKey);

    List<Widget> list = [];

    var listWidget = Selector<DMProvider, DMSession?>(
      builder: (context, session, child) {
        if (session == null) {
          return Container();
        }

        return ListView.builder(
          itemBuilder: (context, index) {
            var event = session.get(index);
            if (event == null) {
              return null;
            }

            return DMDetailItemComponent(
              sessionPubkey: detail!.dmSession.pubkey,
              event: event,
              isLocal: localPubkey == event.pubKey,
              agreement: agreement!,
            );
          },
          reverse: true,
          itemCount: session.length(),
          dragStartBehavior: DragStartBehavior.down,
        );
      },
      selector: (context, _provider) {
        return _provider.getSession(detail!.dmSession.pubkey);
      },
    );

    list.add(Expanded(
      child: Container(
        margin: EdgeInsets.only(
          bottom: Base.BASE_PADDING,
        ),
        child: listWidget,
      ),
    ));

    list.add(Container(
      decoration: BoxDecoration(
        color: scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: Offset(0, -5),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: quill.QuillEditor(
              placeholder: s.What_s_happening,
              controller: editorController,
              scrollController: ScrollController(),
              focusNode: focusNode,
              readOnly: false,
              embedBuilders: [
                MentionUserEmbedBuilder(),
                MentionEventEmbedBuilder(),
                PicEmbedBuilder(),
                VideoEmbedBuilder(),
                LnbcEmbedBuilder(),
                TagEmbedBuilder(),
              ],
              scrollable: true,
              autoFocus: false,
              expands: false,
              // padding: EdgeInsets.zero,
              padding: EdgeInsets.only(
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
              ),
              maxHeight: 300,
            ),
          ),
          TextButton(
            child: Text(
              s.Send,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
            ),
            onPressed: send,
            style: ButtonStyle(),
          )
        ],
      ),
    ));

    list.add(buildEditorBtns(showShadow: false, height: null));
    if (emojiShow) {
      list.add(buildEmojiSelector());
    }

    Widget main = Container(
      width: double.maxFinite,
      height: double.maxFinite,
      child: Column(children: list),
    );

    if (detail!.info == null && detail!.dmSession.newestEvent != null) {
      main = Container(
        width: double.maxFinite,
        height: double.maxFinite,
        child: Stack(
          children: [
            Positioned.fill(child: main),
            Positioned(
              child: GestureDetector(
                onTap: addDmSessionToKnown,
                child: Container(
                  margin: const EdgeInsets.all(Base.BASE_PADDING),
                  height: 30,
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      s.Add_to_known_list,
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
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            RouterUtil.back(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: themeData.appBarTheme.titleTextStyle!.color,
          ),
        ),
        title: nameComponnet,
      ),
      body: main,
    );
  }

  Future<void> send() async {
    var cancelFunc = BotToast.showLoading();
    try {
      var event = await doDocumentSave();
      if (event != null) {
        dmProvider.addEventAndUpdateReadedTime(detail!, event);
        editorController.clear();
        setState(() {});
      }
    } finally {
      cancelFunc.call();
    }
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
      // detail!.info!.readedTime = detail!.dmSession.newestEvent!.createdAt;
      // DMSessionInfoDB.update(detail!.info!);
      dmProvider.updateReadedTime(detail);
    }
  }

  // Future<void> jumpToWriteMessage() async {
  //   var pubkey = detail!.dmSession.pubkey;
  //   List<dynamic> tags = [
  //     ["p", pubkey]
  //   ];
  //   var event = await EditorRouter.open(
  //     context,
  //     agreement: agreement,
  //     pubkey: pubkey,
  //     tags: tags,
  //     tagsAddedWhenSend: [],
  //   );
  //   if (event != null) {
  //     dmProvider.addEventAndUpdateReadedTime(detail!, event);
  //     setState(() {});
  //   }
  // }

  @override
  ECDHBasicAgreement? getAgreement() {
    return agreement;
  }

  @override
  BuildContext getContext() {
    return context;
  }

  @override
  String? getPubkey() {
    return detail!.dmSession.pubkey;
  }

  @override
  List getTags() {
    var pubkey = detail!.dmSession.pubkey;
    List<dynamic> tags = [
      ["p", pubkey]
    ];
    return tags;
  }

  @override
  List getTagsAddedWhenSend() {
    return [];
  }

  @override
  void updateUI() {
    setState(() {});
  }
}
