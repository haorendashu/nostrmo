import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nostrmo/client/upload/uploader.dart';
import 'package:nostrmo/component/editor/cust_embed_types.dart';
import 'package:nostrmo/component/editor/lnbc_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_event_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_user_embed_builder.dart';
import 'package:nostrmo/component/editor/pic_embed_builder.dart';
import 'package:nostrmo/component/editor/tag_embed_builder.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/index/index_app_bar.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';

class EditorRouter extends StatefulWidget {
  List<dynamic> tags = [];

  List<dynamic> tagsAddedWhenSend = [];

  EditorRouter({required this.tags, required this.tagsAddedWhenSend});

  static void open(BuildContext context,
      {List<dynamic>? tags, List<dynamic>? tagsAddedWhenSend}) {
    tags ??= [];
    tagsAddedWhenSend ??= [];
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return EditorRouter(
        tags: tags!,
        tagsAddedWhenSend: tagsAddedWhenSend!,
      );
    }));
  }

  @override
  State<StatefulWidget> createState() {
    return _EditorRouter();
  }
}

class _EditorRouter extends State<EditorRouter> {
  quill.QuillController _controller = quill.QuillController.basic();

  bool emojiShow = false;

  var focusNode = FocusNode();

  late List<dynamic> tags;

  late List<dynamic> tagsAddedWhenSend;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (focusNode.hasFocus && emojiShow) {
        setState(() {
          emojiShow = false;
        });
      }
    });

    tags = widget.tags;
    tagsAddedWhenSend = widget.tagsAddedWhenSend;
  }

  @override
  Widget build(BuildContext context) {
    // TODO embed: image、video、bitcoin
    // TODO embed input: image、video、bitcoin
    // TODO relation input: events、users、emoji
    var themeData = Theme.of(context);
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    var mainColor = themeData.primaryColor;
    var textColor = themeData.textTheme.bodyMedium!.color;

    List<Widget> list = [];
    list.add(Expanded(
      child: quill.QuillEditor(
        placeholder: "What's happening?",
        controller: _controller,
        scrollController: ScrollController(),
        focusNode: focusNode,
        readOnly: false,
        embedBuilders: [
          MentionUserEmbedBuilder(),
          MentionEventEmbedBuilder(),
          PicEmbedBuilder(),
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
    ));
    list.add(
      quill.QuillToolbar(
        toolbarIconAlignment: WrapAlignment.start,
        toolbarIconCrossAlignment: WrapCrossAlignment.start,
        children: [],
      ),
    );
    list.add(Container(
      height: IndexAppBar.height,
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
          quill.QuillIconButton(
            onPressed: pickImage,
            icon: Icon(Icons.image),
          ),
          quill.QuillIconButton(
            onPressed: () {},
            icon: Icon(Icons.camera),
          ),
          quill.QuillIconButton(
            onPressed: _inputLnbc,
            icon: Icon(Icons.bolt),
          ),
          quill.QuillIconButton(
            onPressed: emojiBeginToSelect,
            icon: Icon(Icons.tag_faces),
          ),
          quill.QuillIconButton(
            onPressed: _inputMentionUser,
            icon: Icon(Icons.alternate_email_sharp),
          ),
          quill.QuillIconButton(
            onPressed: _inputMentionEvent,
            icon: Icon(Icons.format_quote),
          ),
          quill.QuillIconButton(
            onPressed: _inputTag,
            icon: Icon(Icons.tag),
          ),
          Expanded(child: Container()),
        ],
      ),
    ));
    if (emojiShow) {
      list.add(Container(
        height: 260,
        child: EmojiPicker(
          onEmojiSelected: (Category? category, Emoji emoji) {
            emojiInsert(emoji);
          },
          onBackspacePressed: null,
          // textEditingController:
          //     textEditionController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
          config: Config(
            columns: 10,
            emojiSizeMax: 20 * (Platform.isIOS ? 1.30 : 1.0),
            verticalSpacing: 0,
            horizontalSpacing: 0,
            gridPadding: EdgeInsets.zero,
            initCategory: Category.RECENT,
            bgColor: Color(0xFFF2F2F2),
            indicatorColor: mainColor,
            iconColor: Colors.grey,
            iconColorSelected: mainColor,
            backspaceColor: mainColor,
            skinToneDialogBgColor: Colors.white,
            skinToneIndicatorColor: Colors.grey,
            enableSkinTones: true,
            showRecentsTab: true,
            recentsLimit: 28,
            noRecents: const Text(
              'No Recents',
              style: TextStyle(fontSize: 14, color: Colors.black26),
              textAlign: TextAlign.center,
            ), // Needs to be const Widget
            loadingIndicator:
                const SizedBox.shrink(), // Needs to be const Widget
            tabIndicatorAnimDuration: kTabScrollDuration,
            categoryIcons: const CategoryIcons(),
            buttonMode: ButtonMode.MATERIAL,
          ),
        ),
      ));
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
                "Send",
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

  Future<void> pickImage() async {
    var filepath = await Uploader.pick(context);
    _imageSubmitted(filepath);
    // _imageSubmitted(
    //     "https://up.enterdesk.com/edpic/0c/ef/a0/0cefa0f17b83255217eddc20b15395f9.jpg");
  }

  void _imageSubmitted(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;

      _controller.replaceText(
          index, length, quill.BlockEmbed.image(value), null);
    }
  }

  void _inputMentionEvent() {
    // this is a random address copy from search
    _submitMentionEvent(
        "ee532be23c8635b77e3e44e0340c5c52812230e4332096aa3c54187d3aea5548");
  }

  void _submitMentionEvent(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;

      _controller.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.mention_evevt, value), null);
    }
  }

  void _inputMentionUser() {
    // this is a random address copy from search
    _submitMentionUser(
        "deab79dafa1c2be4b4a6d3aca1357b6caa0b744bf46ad529a5ae464288579e68");
  }

  void _submitMentionUser(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;

      _controller.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.mention_user, value), null);
    }
  }

  void _inputLnbc() {
    // this is a random address copy from search
    _lnbcSubmitted(
        "lnbc5100n1pjp3p8epp5pvs6d62ek5ahkp9uds8hysl0utgy8mudt90fg5yyuqu6erff8gsqdqu2askcmr9wssx7e3q2dshgmmndp5scqzpgxqyz5vqsp5jadq8t8acpf28wpalpggmgmuz8tzqlpuhjrmxd6k5y4pz8cgx93q9qyyssqa79wuyt4j0x34lln9470qefdkkuqjejcz7nskzls8jlu6qvrhjp4mzq3gchpf6umj6wg02qghguzgfydujqfjhz0kcm72zwdha4f45sqmqn632");
  }

  void _lnbcSubmitted(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;

      _controller.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.lnbc, value), null);
    }
  }

  void _inputTag() {
    // this is a random address copy from search
    _submitTag("Nostr");
  }

  void _submitTag(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;

      _controller.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.tag, value), null);
    }
  }

  Future<void> documentSave() async {
    var cancelFunc = BotToast.showLoading();
    try {
      await _doDocumentSave();
    } finally {
      cancelFunc.call();
    }
  }

  Future<void> _doDocumentSave() async {
    var delta = _controller.document.toDelta();
    var operations = delta.toList();
    String result = "";
    for (var operation in operations) {
      if (operation.key == "insert") {
        if (operation.data is Map) {
          var m = operation.data as Map;
          var value = m["image"];
          if (StringUtil.isNotBlank(value) && value is String) {
            if (value.indexOf("http") != 0) {
              // this is a local image, update it first
              var imagePath = await Uploader.upload(value);
              if (StringUtil.isNotBlank(imagePath)) ;
              value = imagePath;
            }
            result = handleBlockValue(result, value);
            continue;
          }

          value = m["lnbc"];
          if (StringUtil.isNotBlank(value)) {
            result = handleBlockValue(result, value);
            continue;
          }

          value = m["tag"];
          if (StringUtil.isNotBlank(value)) {
            result = handleInlineValue(result, "#" + value);
            tags.add(["tag", value]);
            continue;
          }

          value = m["mentionUser"];
          if (StringUtil.isNotBlank(value)) {
            if (!_lastIsSpace(result) && !_lastIsLineEnd(result)) {
              result += " ";
            }
            tags.add(["p", value, "", "mention"]);
            var index = tags.length - 1;
            result += "#[$index] ";
            continue;
          }

          value = m["mentionEvent"];
          if (StringUtil.isNotBlank(value)) {
            if (!_lastIsLineEnd(result)) {
              result += " ";
            }
            tags.add(["e", value, "", "mention"]);
            var index = tags.length - 1;
            result += "#[$index] ";
            continue;
          }
        } else {
          result += operation.data.toString();
        }
      }
    }
    result = result.trim();
    // log(result);
    // print(tags);
    // print(tagsAddWhenSend);

    List<dynamic> allTags = [];
    allTags.add(tags);
    allTags.add(tagsAddedWhenSend);
    var event = nostr!.sendTextNote(result, allTags);
    RouterUtil.back(context);
  }

  String handleInlineValue(String result, String value) {
    if (!_lastIsSpace(result) && !_lastIsLineEnd(result)) {
      result += " ";
    }
    result += value + " ";
    return result;
  }

  String handleBlockValue(String result, String value) {
    if (!_lastIsLineEnd(result)) {
      result += "\n";
    }
    result += value + "\n";
    return result;
  }

  bool _lastIsSpace(String str) {
    var length = str.length;
    if (str[length - 1] == " ") {
      return true;
    }
    return false;
  }

  bool _lastIsLineEnd(String str) {
    var length = str.length;
    if (str[length - 1] == "\n") {
      return true;
    }
    return false;
  }

  void emojiBeginToSelect() {
    FocusScope.of(context).unfocus();
    // SystemChannels.textInput.invokeMethod('TextInput.hide');
    setState(() {
      emojiShow = true;
    });
  }

  void emojiInsert(Emoji emoji) {
    final index = _controller.selection.baseOffset;
    final length = _controller.selection.extentOffset - index;
    _controller.replaceText(
        index, length, emoji.emoji, TextSelection.collapsed(offset: index + 2),
        ignoreFocus: true);
    setState(() {});
  }
}
