import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:nostr_sdk/aid.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_relation.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/component/editor/lnbc_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_event_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_user_embed_builder.dart';
import 'package:nostrmo/component/editor/pic_embed_builder.dart';
import 'package:nostrmo/component/editor/tag_embed_builder.dart';
import 'package:nostrmo/component/editor/video_embed_builder.dart';
import 'package:nostrmo/component/editor/zap_goal_input_component.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/index/index_app_bar.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:pointycastle/ecc/api.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/cust_state.dart';
import '../../component/editor/custom_emoji_embed_builder.dart';
import '../../component/editor/editor_mixin.dart';
import '../../component/editor/poll_input_component.dart';
import '../../component/editor/zap_split_input_component.dart';
import '../../component/group_identifier_inherited_widget.dart';
import '../../component/user/user_pic_component.dart';
import '../../generated/l10n.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'editor_notify_item_component.dart';

class EditorRouter extends StatefulWidget {
  static double appbarHeight = 56;

  // dm arg
  String? pubkey;

  GroupIdentifier? groupIdentifier;

  int? groupEventKind;

  List<List<dynamic>> tags = [];

  List<List<dynamic>> tagsAddedWhenSend = [];

  List<List<dynamic>> tagPs = [];

  List<BlockEmbed>? initEmbeds;

  bool isLongForm;

  bool isPoll;

  bool isZapGoal;

  Event? repliedEvent;

  EditorRouter({
    required this.tags,
    required this.tagsAddedWhenSend,
    required this.tagPs,
    this.pubkey,
    this.initEmbeds,
    this.groupIdentifier,
    this.groupEventKind,
    this.isLongForm = false,
    this.isPoll = false,
    this.isZapGoal = false,
    this.repliedEvent,
  });

  static Future<Event?> replyEvent(BuildContext context, Event event,
      {EventRelation? eventRelation}) async {
    eventRelation ??= EventRelation.fromEvent(event);

    List<List<dynamic>> tags = [];
    List<List<dynamic>> tagsAddedWhenSend = [];
    String relayAddr = "";
    if (event.sources.isNotEmpty) {
      relayAddr = event.sources[0];
    }
    String directMarked = "reply";
    if (StringUtil.isBlank(eventRelation.rootId)) {
      directMarked = "root";
    }
    tagsAddedWhenSend
        .add(["e", event.id, relayAddr, directMarked, event.pubkey]);

    List<List<dynamic>> tagPs = [];
    tagPs.add(["p", event.pubkey]);
    if (eventRelation.tagPList.isNotEmpty) {
      for (var p in eventRelation.tagPList) {
        tagPs.add(["p", p]);
      }
    }
    if (StringUtil.isNotBlank(eventRelation.rootId)) {
      String relayAddr = "";
      if (StringUtil.isNotBlank(eventRelation.rootRelayAddr)) {
        relayAddr = eventRelation.rootRelayAddr!;
      }
      if (StringUtil.isBlank(relayAddr)) {
        var rootEvent = singleEventProvider.getEvent(eventRelation.rootId!);
        if (rootEvent != null && rootEvent.sources.isNotEmpty) {
          relayAddr = rootEvent.sources[0];
        }
      }
      var tag = ["e", eventRelation.rootId, relayAddr, "root"];
      if (eventRelation.rootPubkey != null) {
        tag.add(eventRelation.pubkey);
      }
      tags.add(tag);
    }

    GroupIdentifier? groupIdentifier;
    int? groupEventKind;
    if (event.kind == EventKind.GROUP_NOTE || event.kind == EventKind.COMMENT) {
      groupIdentifier =
          GroupIdentifierInheritedWidget.getGroupIdentifier(context);
      if (groupIdentifier != null) {
        groupEventKind = EventKind.COMMENT;
      }
    }

    // TODO reply maybe change the placeholder in editor router.
    return await EditorRouter.open(
      context,
      tags: tags,
      tagsAddedWhenSend: tagsAddedWhenSend,
      tagPs: tagPs,
      groupIdentifier: groupIdentifier,
      groupEventKind: groupEventKind,
      repliedEvent: event,
    );
  }

  static Future<Event?> open(
    BuildContext context, {
    List<List<dynamic>>? tags,
    List<List<dynamic>>? tagsAddedWhenSend,
    List<List<dynamic>>? tagPs,
    String? pubkey,
    List<BlockEmbed>? initEmbeds,
    GroupIdentifier? groupIdentifier,
    int? groupEventKind,
    bool isLongForm = false,
    bool isPoll = false,
    bool isZapGoal = false,
    Event? repliedEvent,
  }) {
    tags ??= [];
    tagsAddedWhenSend ??= [];
    tagPs ??= [];

    var editor = EditorRouter(
      tags: tags,
      tagsAddedWhenSend: tagsAddedWhenSend,
      tagPs: tagPs,
      pubkey: pubkey,
      initEmbeds: initEmbeds,
      groupIdentifier: groupIdentifier,
      groupEventKind: groupEventKind,
      isLongForm: isLongForm,
      isPoll: isPoll,
      isZapGoal: isZapGoal,
      repliedEvent: repliedEvent,
    );

    return RouterUtil.push(context, MaterialPageRoute(builder: (context) {
      return editor;
    }));
  }

  @override
  State<StatefulWidget> createState() {
    return _EditorRouter();
  }
}

class _EditorRouter extends CustState<EditorRouter> with EditorMixin {
  List<EditorNotifyItem>? notifyItems;

  List<EditorNotifyItem> editorNotifyItems = [];

  @override
  void initState() {
    super.initState();
    inputPoll = widget.isPoll;
    inputZapGoal = widget.isZapGoal;
    handleFocusInit();
  }

  @override
  GroupIdentifier? getGroupIdentifier() {
    return widget.groupIdentifier;
  }

  @override
  int? getGroupEventKind() {
    return widget.groupEventKind;
  }

  @override
  bool isLongForm() {
    return widget.isLongForm;
  }

  bool _showLongFormInfoInput = true;

  void showLongFormInfoInput() {
    _showLongFormInfoInput = !_showLongFormInfoInput;
    updateUI();
  }

  bool firstTap = true;

  @override
  Widget doBuild(BuildContext context) {
    if (notifyItems == null) {
      notifyItems = [];
      for (var tagP in widget.tagPs) {
        if (tagP is List<dynamic> && tagP.length > 1) {
          notifyItems!.add(EditorNotifyItem(pubkey: tagP[1]));
        }
      }
    }

    var s = S.of(context);
    var themeData = Theme.of(context);
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    var mainColor = themeData.primaryColor;
    var hintColor = themeData.hintColor;
    var textColor = themeData.textTheme.bodyMedium!.color;
    var cardColor = themeData.cardColor;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;

    List<Widget> list = [];

    if (widget.tags.isNotEmpty) {
      for (var tag in widget.tags) {
        if (tag.length > 1) {
          var tagName = tag[0];
          var tagValue = tag[1];

          if (tagName == "a") {
            // this note is add to community
            var aid = AId.fromString(tagValue);
            if (aid != null && aid.kind == EventKind.COMMUNITY_DEFINITION) {
              list.add(Container(
                padding: const EdgeInsets.only(
                  left: Base.BASE_PADDING,
                  right: Base.BASE_PADDING,
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: Base.BASE_PADDING),
                      child: Icon(
                        Icons.groups,
                        size: largeTextSize,
                        color: hintColor,
                      ),
                    ),
                    Text(
                      aid.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ));
            }
          }
        }
      }
    }

    if (widget.repliedEvent != null) {
      var textStyle = TextStyle(
        fontSize: smallTextSize,
      );
      List<Widget> replyingList = [];
      replyingList.add(Text(
        "${s.Replying}: ",
        style: textStyle,
      ));

      replyingList.add(Container(
        margin: const EdgeInsets.only(
          left: Base.BASE_PADDING_HALF,
        ),
        child: UserPicComponent(
          pubkey: widget.repliedEvent!.pubkey,
          width: themeData.textTheme.bodyLarge!.fontSize!,
        ),
      ));
      replyingList.add(Expanded(
          child: Container(
        margin: const EdgeInsets.only(
          left: Base.BASE_PADDING_HALF,
          right: 30,
        ),
        child: Text(
          widget.repliedEvent!.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
      )));

      list.add(Container(
        width: double.maxFinite,
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING,
          bottom: Base.BASE_PADDING_HALF,
        ),
        margin: const EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        child: Row(
          children: replyingList,
        ),
      ));
    }

    if ((notifyItems != null && notifyItems!.isNotEmpty) ||
        (editorNotifyItems.isNotEmpty)) {
      List<Widget> tagPsWidgets = [];
      tagPsWidgets.add(Text("${s.Notify}:"));
      for (var item in notifyItems!) {
        tagPsWidgets.add(EditorNotifyItemComponent(item: item));
      }
      for (var editorNotifyItem in editorNotifyItems) {
        var exist = notifyItems!.any((element) {
          return element.pubkey == editorNotifyItem.pubkey;
        });
        if (!exist) {
          tagPsWidgets.add(EditorNotifyItemComponent(item: editorNotifyItem));
        }
      }
      list.add(Container(
        padding:
            EdgeInsets.only(left: Base.BASE_PADDING, right: Base.BASE_PADDING),
        margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
        width: double.maxFinite,
        child: Wrap(
          spacing: Base.BASE_PADDING_HALF,
          runSpacing: Base.BASE_PADDING_HALF,
          children: tagPsWidgets,
          crossAxisAlignment: WrapCrossAlignment.center,
        ),
      ));
    }

    if (showTitle) {
      list.add(buildTitleWidget());
    }

    if (isLongForm()) {
      var showIconData = Icons.expand_more;
      if (_showLongFormInfoInput) {
        list.add(buildTitleWidget());
        list.add(buildLongFormImageWidget());
        list.add(buildSummaryWidget());

        showIconData = Icons.expand_less;
      }

      list.add(GestureDetector(
        onTap: showLongFormInfoInput,
        child: Container(
          margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
          child: Icon(showIconData),
        ),
      ));
    }

    if (publishAt != null) {
      var dateFormate = DateFormat("yyyy-MM-dd HH:mm");

      list.add(GestureDetector(
        onTap: selectedTime,
        behavior: HitTestBehavior.translucent,
        child: Container(
          margin: EdgeInsets.only(left: 10, bottom: Base.BASE_PADDING_HALF),
          child: Row(
            children: [
              Icon(Icons.timer_outlined),
              Container(
                margin: EdgeInsets.only(left: 4),
                child: Text(
                  dateFormate.format(publishAt!),
                ),
              ),
            ],
          ),
        ),
      ));
    }

    Widget quillWidget = QuillEditor(
      controller: editorController,
      config: QuillEditorConfig(
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
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING,
          right: Base.BASE_PADDING,
        ),
        onTapUp: (details, offset) {
          checkAndInsertNoteTail();
          return false;
        },
        customStyleBuilder: (Attribute attribute) {
          return TextStyle();
        },
        customStyles: DefaultStyles(),
        enableInteractiveSelection: true,
        enableSelectionToolbar: true,
      ),
      scrollController: ScrollController(),
      focusNode: focusNode,
    );
    List<Widget> editorList = [];
    var editorInputWidget = Container(
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING),
      child: quillWidget,
    );
    editorList.add(editorInputWidget);
    if (inputPoll) {
      editorList.add(PollInputComponent(
        pollInputController: pollInputController,
      ));
    }
    if (inputZapGoal) {
      editorList.add(ZapGoalInputComponent(
        zapGoalInputController: zapGoalInputController,
      ));
    }
    if (openZapSplit) {
      editorList.add(ZapSplitInputComponent(eventZapInfos));
    }

    list.add(Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // focus to eidtor input widget
          focusNode.requestFocus();

          checkAndInsertNoteTail();
        },
        child: Container(
          constraints: BoxConstraints(
              maxHeight: mediaDataCache.size.height -
                  mediaDataCache.padding.top -
                  EditorRouter.appbarHeight -
                  IndexAppBar.height),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: editorList,
            ),
          ),
        ),
      ),
    ));

    list.add(buildEditorBtns());
    if (emojiShow) {
      list.add(buildEmojiSelector());
    }
    if (customEmojiShow) {
      list.add(buildEmojiListsWidget());
    }

    return Scaffold(
      appBar: AppBar(
        // title: Text("Note"),
        backgroundColor: cardColor,
        leading: AppbarBackBtnComponent(),
        actions: [
          Container(
            child: TextButton(
              child: Text(
                s.Send,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                ),
              ),
              onPressed: documentSave,
              style: ButtonStyle(),
            ),
          ),
        ],
      ),
      body: Container(
        color: cardColor,
        child: Column(
          children: list,
        ),
      ),
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    if (widget.initEmbeds != null && widget.initEmbeds!.isNotEmpty) {
      {
        final index = editorController.selection.baseOffset;
        final length = editorController.selection.extentOffset - index;

        editorController.replaceText(index, length, "\n", null);

        editorController.moveCursorToPosition(index + 1);
      }

      for (var embed in widget.initEmbeds!) {
        final index = editorController.selection.baseOffset;
        final length = editorController.selection.extentOffset - index;

        editorController.replaceText(index, length, embed, null);

        editorController.moveCursorToPosition(index + 1);
      }

      editorController.moveCursorToPosition(0);
    }

    editorNotifyItems = [];
    editorController.addListener(() {
      bool updated = false;
      Map<String, int> mentionUserMap = {};

      var delta = editorController.document.toDelta();
      var operations = delta.toList();
      for (var operation in operations) {
        if (operation.key == "insert") {
          if (operation.data is Map) {
            var m = operation.data as Map;
            var value = m["mentionUser"];
            if (StringUtil.isNotBlank(value)) {
              mentionUserMap[value] = 1;
            }
          }
        }
      }

      List<EditorNotifyItem> needDeleds = [];
      for (var item in editorNotifyItems!) {
        var exist = mentionUserMap.remove(item.pubkey);
        if (exist == null) {
          updated = true;
          needDeleds.add(item);
        }
      }
      editorNotifyItems!.removeWhere((element) => needDeleds.contains(element));

      if (mentionUserMap.isNotEmpty) {
        var entries = mentionUserMap.entries;
        for (var entry in entries) {
          updated = true;
          editorNotifyItems.add(EditorNotifyItem(pubkey: entry.key));
        }
      }

      if (updated) {
        setState(() {});
      }
    });
  }

  Future<void> documentSave() async {
    var cancelFunc = BotToast.showLoading();
    try {
      var event = await doDocumentSave();
      if (event == null) {
        BotToast.showText(text: S.of(context).Send_fail);
        return;
      }
      RouterUtil.back(context, event);
    } finally {
      cancelFunc.call();
    }
  }

  @override
  BuildContext getContext() {
    return context;
  }

  @override
  void updateUI() {
    setState(() {});
  }

  @override
  String? getPubkey() {
    return widget.pubkey;
  }

  @override
  List<List<dynamic>> getTags() {
    return widget.tags;
  }

  @override
  List<List<dynamic>> getTagsAddedWhenSend() {
    if ((notifyItems == null || notifyItems!.isEmpty) &&
        editorNotifyItems.isEmpty) {
      return widget.tagsAddedWhenSend;
    }

    List<List<dynamic>> list = [];
    list.addAll(widget.tagsAddedWhenSend);
    for (var item in notifyItems!) {
      if (item.selected) {
        list.add(["p", item.pubkey]);
      }
    }

    for (var editorNotifyItem in editorNotifyItems) {
      var exist = notifyItems!.any((element) {
        return element.pubkey == editorNotifyItem.pubkey;
      });
      if (!exist) {
        if (editorNotifyItem.selected) {
          list.add(["p", editorNotifyItem.pubkey]);
        }
      }
    }

    return list;
  }

  @override
  bool isDM() {
    return false;
  }

  void checkAndInsertNoteTail() {
    if (firstTap && StringUtil.isNotBlank(settingProvider.noteTail)) {
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      editorController.replaceText(
          index, length, settingProvider.noteTail, null);
    }
    firstTap = false;
  }
}
