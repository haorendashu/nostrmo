import 'dart:developer';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/nip04/nip04.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/client/upload/uploader.dart';
import 'package:nostrmo/component/editor/cust_embed_types.dart';
import 'package:nostrmo/component/editor/lnbc_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_event_embed_builder.dart';
import 'package:nostrmo/component/editor/mention_user_embed_builder.dart';
import 'package:nostrmo/component/editor/pic_embed_builder.dart';
import 'package:nostrmo/component/editor/tag_embed_builder.dart';
import 'package:nostrmo/component/editor/text_input_dialog.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/index/index_app_bar.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:pointycastle/ecc/api.dart';

import '../../client/event_kind.dart' as kind;

class EditorRouter extends StatefulWidget {
  // dm arg
  ECDHBasicAgreement? agreement;

  // dm arg
  String? pubkey;

  List<dynamic> tags = [];

  List<dynamic> tagsAddedWhenSend = [];

  EditorRouter({
    required this.tags,
    required this.tagsAddedWhenSend,
    this.agreement,
    this.pubkey,
  });

  static Future<Event?> open(
    BuildContext context, {
    List<dynamic>? tags,
    List<dynamic>? tagsAddedWhenSend,
    ECDHBasicAgreement? agreement,
    String? pubkey,
  }) {
    tags ??= [];
    tagsAddedWhenSend ??= [];
    return Navigator.push(context, MaterialPageRoute(builder: (context) {
      return EditorRouter(
        tags: tags!,
        tagsAddedWhenSend: tagsAddedWhenSend!,
        agreement: agreement,
        pubkey: pubkey,
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
      child: Container(
        margin: EdgeInsets.only(bottom: Base.BASE_PADDING),
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
            onPressed: takeAPhoto,
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

      _controller.moveCursorToPosition(index + 1);
    }
  }

  Future<void> takeAPhoto() async {
    ImagePicker _picker = ImagePicker();
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _imageSubmitted(photo.path);
    }
  }

  Future<void> _inputMentionEvent() async {
    var value = await TextInputDialog.show(context, "Please input event id",
        hintText: "event id");
    if (StringUtil.isNotBlank(value)) {
      // check nip19 value
      if (Nip19.isNoteId(value!)) {
        value = Nip19.decode(value);
      }
      _submitMentionEvent(value);
    }
  }

  void _submitMentionEvent(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;

      _controller.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.mention_evevt, value), null);

      _controller.moveCursorToPosition(index + 1);
    }
  }

  Future<void> _inputMentionUser() async {
    var value = await TextInputDialog.show(context, "Please input user pubkey",
        hintText: "user pubkey");
    if (StringUtil.isNotBlank(value)) {
      // check nip19 value
      if (Nip19.isPubkey(value!)) {
        value = Nip19.decode(value);
      }
      _submitMentionUser(value);
    }
  }

  void _submitMentionUser(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;

      _controller.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.mention_user, value), null);

      _controller.moveCursorToPosition(index + 1);
    }
  }

  Future<void> _inputLnbc() async {
    var value = await TextInputDialog.show(context, "Please input lnbc text",
        hintText: "lnbc...");
    if (StringUtil.isNotBlank(value)) {
      _lnbcSubmitted(value);
    }
  }

  void _lnbcSubmitted(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;

      _controller.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.lnbc, value), null);

      _controller.moveCursorToPosition(index + 1);
    }
  }

  Future<void> _inputTag() async {
    var value = await TextInputDialog.show(context, "Please input Topic text",
        valueCheck: baseInputCheck, hintText: "Topic");
    if (StringUtil.isNotBlank(value)) {
      _submitTag(value);
    }
  }

  bool baseInputCheck(BuildContext context, String value) {
    if (value.contains(" ")) {
      BotToast.showText(text: "Text can't contain blank space");
      return false;
    }
    if (value.contains("\n")) {
      BotToast.showText(text: "Text can't contain new line");
      return false;
    }
    return true;
  }

  void _submitTag(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;

      _controller.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.tag, value), null);

      _controller.moveCursorToPosition(index + 1);
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
            tags.add(["p", value]);
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
    allTags.addAll(tags);
    allTags.addAll(tagsAddedWhenSend);
    Event? event;
    if (widget.agreement != null && StringUtil.isNotBlank(widget.pubkey)) {
      // dm message
      result = NIP04.encrypt(result, widget.agreement!, widget.pubkey!);
      event = Event(
          nostr!.publicKey, kind.EventKind.DIRECT_MESSAGE, allTags, result);
    } else {
      // text note
      event =
          Event(nostr!.publicKey, kind.EventKind.TEXT_NOTE, allTags, result);
    }
    nostr!.sendEvent(event);
    RouterUtil.back(context, event);
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
    if (StringUtil.isBlank(str)) {
      return true;
    }

    var length = str.length;
    if (str[length - 1] == " ") {
      return true;
    }
    return false;
  }

  bool _lastIsLineEnd(String str) {
    if (StringUtil.isBlank(str)) {
      return true;
    }

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
