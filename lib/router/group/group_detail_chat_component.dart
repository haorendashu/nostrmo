import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:loading_more_list/loading_more_list.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:nostrmo/util/load_more_event.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../component/editor/custom_emoji_embed_builder.dart';
import '../../component/editor/editor_mixin.dart';
import '../../component/editor/lnbc_embed_builder.dart';
import '../../component/editor/mention_event_embed_builder.dart';
import '../../component/editor/mention_user_embed_builder.dart';
import '../../component/editor/pic_embed_builder.dart';
import '../../component/editor/tag_embed_builder.dart';
import '../../component/editor/video_embed_builder.dart';
import '../../component/events_loading_more_repo.dart';
import '../../component/keep_alive_cust_state.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../dm/dm_detail_item_component.dart';

class GroupDetailChatComponent extends StatefulWidget {
  GroupIdentifier groupIdentifier;

  GroupDetailChatComponent(this.groupIdentifier);

  @override
  State<StatefulWidget> createState() {
    return _GroupDetailChatComponent();
  }
}

class _GroupDetailChatComponent
    extends KeepAliveCustState<GroupDetailChatComponent> with EditorMixin {
  GroupDetailProvider? groupDetailProvider;

  ClampingScrollPhysics scrollPhysics = ClampingScrollPhysics();

  EventsLoadingMoreRepo eventsLoadingMoreRepo = EventsLoadingMoreRepo();

  @override
  void initState() {
    super.initState();
    handleFocusInit();

    eventsLoadingMoreRepo.getEventBox = getEventBox;
    eventsLoadingMoreRepo.doQuery = doQuery;
  }

  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);
    var textColor = themeData.textTheme.bodyMedium!.color;
    var cardColor = themeData.cardColor;
    var s = S.of(context);

    groupDetailProvider = Provider.of<GroupDetailProvider>(context);

    var localPubkey = nostr!.publicKey;

    List<Widget> list = [];

    Widget listWidget = LoadingMoreList<Event>(ListConfig<Event>(
      itemBuilder: (BuildContext context, Event event, int index) {
        return DMDetailItemComponent(
          sessionPubkey: event.pubkey, // this pubkey maybe should setto null
          event: event,
          isLocal: localPubkey == event.pubkey,
        );
      },
      sourceList: eventsLoadingMoreRepo,
      dragStartBehavior: DragStartBehavior.down,
      reverse: true,
    ));
    list.add(Expanded(
      child: Container(
        margin: const EdgeInsets.only(
          bottom: Base.BASE_PADDING,
          top: Base.BASE_PADDING,
        ),
        child: listWidget,
      ),
    ));

    list.add(Container(
      decoration: BoxDecoration(
        color: cardColor,
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
              configurations: quill.QuillEditorConfigurations(
                placeholder: s.What_s_happening,
                embedBuilders: [
                  MentionUserEmbedBuilder(),
                  MentionEventEmbedBuilder(),
                  PicEmbedBuilder(),
                  VideoEmbedBuilder(),
                  LnbcEmbedBuilder(),
                  TagEmbedBuilder(),
                  CustomEmojiEmbedBuilder(),
                ],
                scrollable: true,
                autoFocus: false,
                expands: false,
                // padding: EdgeInsets.zero,
                padding: EdgeInsets.only(
                  left: Base.BASE_PADDING,
                  right: Base.BASE_PADDING,
                ),
                maxHeight: 300, controller: editorController,
              ),
              scrollController: ScrollController(),
              focusNode: focusNode,
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
    if (customEmojiShow) {
      list.add(buildEmojiListsWidget());
    }

    return Container(
      width: double.maxFinite,
      height: double.maxFinite,
      child: Column(children: list),
    );
  }

  Future<void> send() async {
    var cancelFunc = BotToast.showLoading();
    try {
      var event = await doDocumentSave();
      if (event == null) {
        BotToast.showText(text: S.of(context).Send_fail);
        return;
      }

      editorController.clear();
      setState(() {});
    } finally {
      cancelFunc.call();
    }
  }

  @override
  Future<void> onReady(BuildContext context) async {}

  @override
  BuildContext getContext() {
    return context;
  }

  @override
  List getTags() {
    return [];
  }

  @override
  List getTagsAddedWhenSend() {
    List<dynamic> tags = [];
    var previousTag = ["previous", ...groupDetailProvider!.chatsPrevious()];
    tags.add(previousTag);
    return tags;
  }

  @override
  void updateUI() {
    setState(() {});
  }

  @override
  bool isDM() {
    return false;
  }

  @override
  String? getPubkey() {
    return null;
  }

  void doQuery() {
    groupDetailProvider!.doQueryChats(eventsLoadingMoreRepo.until);
  }

  EventMemBox getEventBox() {
    return groupDetailProvider!.notesBox;
  }

  @override
  GroupIdentifier? getGroupIdentifier() {
    return widget.groupIdentifier;
  }

  @override
  int? getGroupEventKind() {
    return EventKind.GROUP_CHAT_MESSAGE;
  }
}
