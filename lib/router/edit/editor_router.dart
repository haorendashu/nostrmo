import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import 'package:nostrmo/client/nip172/community_id.dart';
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

import '../../client/event.dart';
import '../../client/event_kind.dart' as kind;
import '../../component/cust_state.dart';
import '../../component/editor/custom_emoji_embed_builder.dart';
import '../../component/editor/editor_mixin.dart';
import '../../component/editor/poll_input_component.dart';
import '../../generated/l10n.dart';
import '../../util/string_util.dart';
import 'editor_notify_item_component.dart';

class EditorRouter extends StatefulWidget {
  static double appbarHeight = 56;

  // dm arg
  ECDHBasicAgreement? agreement;

  // dm arg
  String? pubkey;

  List<dynamic> tags = [];

  List<dynamic> tagsAddedWhenSend = [];

  List<dynamic> tagPs = [];

  List<quill.BlockEmbed>? initEmbeds;

  EditorRouter({
    required this.tags,
    required this.tagsAddedWhenSend,
    required this.tagPs,
    this.agreement,
    this.pubkey,
    this.initEmbeds,
  });

  static Future<Event?> open(
    BuildContext context, {
    List<dynamic>? tags,
    List<dynamic>? tagsAddedWhenSend,
    List<dynamic>? tagPs,
    ECDHBasicAgreement? agreement,
    String? pubkey,
    List<quill.BlockEmbed>? initEmbeds,
  }) {
    tags ??= [];
    tagsAddedWhenSend ??= [];
    tagPs ??= [];

    var editor = EditorRouter(
      tags: tags,
      tagsAddedWhenSend: tagsAddedWhenSend,
      tagPs: tagPs,
      agreement: agreement,
      pubkey: pubkey,
      initEmbeds: initEmbeds,
    );

    return RouterUtil.push(context, MaterialPageRoute(builder: (context) {
      return editor;
    }));
    // return Navigator.push(context, MaterialPageRoute(builder: (context) {
    //   return editor;
    // }));
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
    handleFocusInit();
  }

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
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;

    List<Widget> list = [];

    if (widget.tags.isNotEmpty) {
      for (var tag in widget.tags) {
        if (tag.length > 1) {
          var tagName = tag[0];
          var tagValue = tag[1];

          if (tagName == "a") {
            // this note is add to community
            var aid = CommunityId.fromString(tagValue);
            if (aid != null) {
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

    Widget quillWidget = quill.QuillProvider(
      configurations: quill.QuillConfigurations(
        controller: editorController,
      ),
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
        ),
        scrollController: ScrollController(),
        focusNode: focusNode,
      ),
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

    list.add(Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // focus to eidtor input widget
          focusNode.requestFocus();
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
      list.add(buildCustomEmojiSelector());
    }

    return Scaffold(
      appBar: AppBar(
        // title: Text("Note"),
        backgroundColor: scaffoldBackgroundColor,
        leading: TextButton(
          child: Icon(
            Icons.arrow_back_ios,
            color: textColor,
          ),
          onPressed: () {
            RouterUtil.back(context);
          },
          style: ButtonStyle(),
        ),
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
  ECDHBasicAgreement? getAgreement() {
    return widget.agreement;
  }

  @override
  String? getPubkey() {
    return widget.pubkey;
  }

  @override
  List getTags() {
    return widget.tags;
  }

  @override
  List getTagsAddedWhenSend() {
    if ((notifyItems == null || notifyItems!.isEmpty) &&
        editorNotifyItems.isEmpty) {
      return widget.tagsAddedWhenSend;
    }

    List<dynamic> list = [];
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
}
