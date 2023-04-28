import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:nostrmo/client/nip04/nip04.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/client/upload/uploader.dart';
import 'package:nostrmo/component/content/content_decoder.dart';
import 'package:nostrmo/component/editor/cust_embed_types.dart';
import 'package:nostrmo/component/editor/lnbc_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_event_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_user_embed_builder.dart';
import 'package:nostrmo/component/editor/pic_embed_builder.dart';
import 'package:nostrmo/component/editor/tag_embed_builder.dart';
import 'package:nostrmo/component/editor/text_input_dialog.dart';
import 'package:nostrmo/component/editor/video_embed_builder.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/edit/poll_input_component.dart';
import 'package:nostrmo/router/index/index_app_bar.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:pointycastle/ecc/api.dart';

import '../../client/event.dart';
import '../../client/event_kind.dart' as kind;
import '../../component/cust_state.dart';
import '../../component/editor/editor_mixin.dart';
import '../../component/editor/gen_lnbc_component.dart';
import '../../component/editor/search_mention_event_component.dart';
import '../../component/editor/search_mention_user_component.dart';
import '../../component/editor/text_input_and_search_dialog.dart';
import '../../generated/l10n.dart';

class EditorRouter extends StatefulWidget {
  static double appbarHeight = 56;

  // dm arg
  ECDHBasicAgreement? agreement;

  // dm arg
  String? pubkey;

  List<dynamic> tags = [];

  List<dynamic> tagsAddedWhenSend = [];

  List<quill.BlockEmbed>? initEmbeds;

  EditorRouter({
    required this.tags,
    required this.tagsAddedWhenSend,
    this.agreement,
    this.pubkey,
    this.initEmbeds,
  });

  static Future<Event?> open(
    BuildContext context, {
    List<dynamic>? tags,
    List<dynamic>? tagsAddedWhenSend,
    ECDHBasicAgreement? agreement,
    String? pubkey,
    List<quill.BlockEmbed>? initEmbeds,
  }) {
    tags ??= [];
    tagsAddedWhenSend ??= [];

    var editor = EditorRouter(
      tags: tags,
      tagsAddedWhenSend: tagsAddedWhenSend,
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
  @override
  void initState() {
    super.initState();
    handleFocusInit();
  }

  @override
  Widget doBuild(BuildContext context) {
    var s = S.of(context);
    var themeData = Theme.of(context);
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    var mainColor = themeData.primaryColor;
    var textColor = themeData.textTheme.bodyMedium!.color;

    List<Widget> list = [];

    List<Widget> editorList = [];
    var editorInputWidget = Container(
      margin: EdgeInsets.only(bottom: Base.BASE_PADDING),
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
      ),
    );
    editorList.add(editorInputWidget);
    if (inputPoll) {
      editorList.add(PollInputComponent(
        pollInputController: pollInputController,
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
                  fontSize: 16,
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
  }

  Future<void> documentSave() async {
    var cancelFunc = BotToast.showLoading();
    try {
      var event = await doDocumentSave();
      if (event == null) {
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
    return widget.tagsAddedWhenSend;
  }
}
