import 'dart:io';

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:nostrmo/component/editor/pic_embed_builder.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/string_util.dart';

class EditorRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _EditorRouter();
  }
}

class _EditorRouter extends State<EditorRouter> {
  quill.QuillController _controller = quill.QuillController.basic();

  bool emojiShow = false;

  var focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      print("hasFocus " + focusNode.hasFocus.toString());
      if (focusNode.hasFocus && emojiShow) {
        setState(() {
          emojiShow = false;
        });
      }
    });
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
          PicEmbedBuilder(),
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
            onPressed: () {},
            icon: Icon(Icons.currency_bitcoin),
          ),
          quill.QuillIconButton(
            onPressed: emojiBeginToSelect,
            icon: Icon(Icons.tag_faces),
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

  void pickImage() {
    _imageSubmitted(
        "https://up.enterdesk.com/edpic/0c/ef/a0/0cefa0f17b83255217eddc20b15395f9.jpg");
  }

  void _imageSubmitted(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;

      _controller.replaceText(
          index, length, quill.BlockEmbed.image(value), null);
    }
  }

  void documentSave() {
    var delta = _controller.document.toDelta();
    var operations = delta.toList();
    String result = "";
    for (var operation in operations) {
      if (operation.key == "insert") {
        if (operation.data is Map) {
          var image = (operation.data as Map)["image"];
          if (StringUtil.isNotBlank(image)) {
            result += image;
          }
        } else {
          result += operation.data.toString();
        }
      }
    }

    var event = nostr!.sendTextNote(result);
    RouterUtil.back(context);
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
