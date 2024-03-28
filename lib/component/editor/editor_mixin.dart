import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbols.dart';
import 'package:nostrmo/client/nip59/gift_wrap_util.dart';
import 'package:nostrmo/component/comfirm_dialog.dart';
import 'package:nostrmo/component/content/content_custom_emoji_component.dart';
import 'package:nostrmo/component/datetime_picker_component.dart';
import 'package:nostrmo/component/editor/zap_goal_input_component.dart';
import 'package:nostrmo/component/webview_router.dart';
import 'package:nostrmo/provider/custom_emoji_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/sendbox/sendbox.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:provider/provider.dart';

import '../../client/event.dart';
import '../../client/event_kind.dart' as kind;
import '../../client/nip04/nip04.dart';
import '../../client/nip19/nip19.dart';
import '../../client/nip19/nip19_tlv.dart';
import '../../client/upload/uploader.dart';
import '../../consts/base.dart';
import '../../data/custom_emoji.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../router/index/index_app_bar.dart';
import '../../util/platform_util.dart';
import '../../util/string_util.dart';
import '../content/content_decoder.dart';
import '../image_component.dart';
import 'cust_embed_types.dart';
import 'custom_emoji_add_dialog.dart';
import 'gen_lnbc_component.dart';
import 'poll_input_component.dart';
import 'search_mention_event_component.dart';
import 'search_mention_user_component.dart';
import 'text_input_and_search_dialog.dart';
import 'text_input_dialog.dart';

mixin EditorMixin {
  quill.QuillController editorController = quill.QuillController.basic();

  PollInputController pollInputController = PollInputController();

  ZapGoalInputController zapGoalInputController = ZapGoalInputController();

  var focusNode = FocusNode();

  bool inputPoll = false;

  bool inputZapGoal = false;

  bool openPrivateDM = false;

  // dm arg
  ECDHBasicAgreement? getAgreement();

  // dm arg
  String? getPubkey();

  BuildContext getContext();

  void updateUI();

  List<dynamic> getTags();

  List<dynamic> getTagsAddedWhenSend();

  void handleFocusInit() {
    focusNode.addListener(() {
      if (focusNode.hasFocus && (emojiShow || customEmojiShow)) {
        emojiShow = false;
        customEmojiShow = false;
        updateUI();
      }
    });
  }

  Widget buildEditorBtns({
    bool showShadow = true,
    double? height = IndexAppBar.height,
  }) {
    var themeData = Theme.of(getContext());
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    var hintColor = themeData.hintColor;
    var mainColor = themeData.primaryColor;

    List<Widget> inputBtnList = [];
    if (getAgreement() != null) {
      inputBtnList.add(quill.QuillToolbarIconButton(
        onPressed: changePrivateDM,
        icon: Icon(Icons.enhanced_encryption,
            color: openPrivateDM ? mainColor : null),
      ));
    }
    if (!PlatformUtil.isWeb()) {
      inputBtnList.add(quill.QuillToolbarIconButton(
        onPressed: pickImage,
        icon: Icon(Icons.image),
      ));
    }
    if (!PlatformUtil.isPC() && !PlatformUtil.isWeb()) {
      inputBtnList.add(quill.QuillToolbarIconButton(
        onPressed: takeAPhoto,
        icon: Icon(Icons.camera),
      ));
      inputBtnList.add(quill.QuillToolbarIconButton(
        onPressed: tackAVideo,
        icon: Icon(Icons.video_call),
      ));
    }
    inputBtnList.addAll([
      quill.QuillToolbarIconButton(
        onPressed: _inputLnbc,
        icon: Icon(Icons.bolt),
      ),
      quill.QuillToolbarIconButton(
        onPressed: customEmojiSelect,
        icon: Icon(Icons.add_reaction_outlined),
      ),
      quill.QuillToolbarIconButton(
        onPressed: emojiBeginToSelect,
        icon: Icon(Icons.tag_faces),
      ),
      quill.QuillToolbarIconButton(
        onPressed: _inputMentionUser,
        icon: Icon(Icons.alternate_email_sharp),
      ),
      quill.QuillToolbarIconButton(
        onPressed: _inputMentionEvent,
        icon: Icon(Icons.format_quote),
      ),
      quill.QuillToolbarIconButton(
        onPressed: _inputTag,
        icon: Icon(Icons.tag),
      ),
      // Expanded(child: Container())
    ]);

    if (getAgreement() == null) {
      inputBtnList.addAll([
        quill.QuillToolbarIconButton(
          onPressed: _addWarning,
          icon: Icon(Icons.warning, color: showWarning ? Colors.red : null),
        ),
        quill.QuillToolbarIconButton(
          onPressed: _addTitle,
          icon: Icon(Icons.title, color: showTitle ? mainColor : null),
        ),
        quill.QuillToolbarIconButton(
          onPressed: selectedTime,
          icon: Icon(Icons.timer_outlined,
              color: publishAt != null ? mainColor : null),
        )
      ]);
    }
    if (getAgreement() == null &&
        getTags().isEmpty &&
        getTagsAddedWhenSend().isEmpty) {
      // isn't dm and reply

      inputBtnList.add(quill.QuillToolbarIconButton(
        onPressed: _inputPoll,
        icon: Icon(Icons.poll, color: inputPoll ? mainColor : null),
        // fillColor: inputPoll ? mainColor.withOpacity(0.5) : null,
      ));
      inputBtnList.add(quill.QuillToolbarIconButton(
        onPressed: _inputGoal,
        icon: Icon(Icons.trending_up, color: inputZapGoal ? mainColor : null),
        // fillColor: inputZapGoal ? mainColor.withOpacity(0.5) : null,
      ));
    }

    inputBtnList.add(
      Container(
        width: Base.BASE_PADDING,
      ),
    );

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: scaffoldBackgroundColor,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: Offset(0, -5),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: inputBtnList,
        ),
      ),
    );
  }

  Widget buildEmojiSelector() {
    var themeData = Theme.of(getContext());
    var mainColor = themeData.primaryColor;
    var bgColor = themeData.scaffoldBackgroundColor;

    return Container(
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
          emojiSizeMax: 20 * (PlatformUtil.isIOS() ? 1.30 : 1.0),
          verticalSpacing: 0,
          horizontalSpacing: 0,
          gridPadding: EdgeInsets.zero,
          initCategory: Category.RECENT,
          bgColor: bgColor,
          indicatorColor: mainColor,
          iconColor: Colors.grey,
          iconColorSelected: mainColor,
          backspaceColor: mainColor,
          skinToneDialogBgColor: Colors.white,
          skinToneIndicatorColor: Colors.grey,
          enableSkinTones: true,
          // showRecentsTab: true,
          recentTabBehavior: RecentTabBehavior.RECENT,
          recentsLimit: 30,
          emojiTextStyle:
              PlatformUtil.isWeb() ? GoogleFonts.notoColorEmoji() : null,
          noRecents: Text(
            'No Recents',
            style: TextStyle(fontSize: 14, color: Colors.black26),
            textAlign: TextAlign.center,
          ), // Needs to be const Widget
          loadingIndicator: const SizedBox.shrink(), // Needs to be const Widget
          tabIndicatorAnimDuration: kTabScrollDuration,
          categoryIcons: const CategoryIcons(),
          buttonMode: ButtonMode.MATERIAL,
        ),
      ),
    );
  }

  bool emojiShow = false;

  void emojiBeginToSelect() {
    FocusScope.of(getContext()).unfocus();
    emojiShow = true;
    customEmojiShow = false;
    updateUI();
  }

  void emojiInsert(Emoji emoji) {
    final index = editorController.selection.baseOffset;
    final length = editorController.selection.extentOffset - index;
    editorController.replaceText(
        index, length, emoji.emoji, TextSelection.collapsed(offset: index + 2),
        ignoreFocus: true);
    updateUI();
  }

  Future<void> changePrivateDM() async {
    if (!openPrivateDM) {
      var context = getContext();
      var result = await ComfirmDialog.show(
          getContext(), S.of(context).Private_DM_Notice);
      if (result == false || result == null) {
        return;
      }
    }

    openPrivateDM = !openPrivateDM;
    updateUI();
  }

  Future<void> pickImage() async {
    var filepath = await Uploader.pick(getContext());
    _imageSubmitted(filepath);
  }

  void _imageSubmitted(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      var fileType = ContentDecoder.getPathType(value);
      if (fileType == "image") {
        editorController.replaceText(
            index, length, quill.BlockEmbed.image(value), null);

        editorController.moveCursorToPosition(index + 1);
      } else if (fileType == "video") {
        editorController.replaceText(
            index, length, quill.BlockEmbed.video(value), null);

        editorController.moveCursorToPosition(index + 1);
      }
    }
  }

  Future<void> takeAPhoto() async {
    ImagePicker _picker = ImagePicker();
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _imageSubmitted(photo.path);
    }
  }

  Future<void> tackAVideo() async {
    ImagePicker _picker = ImagePicker();
    final XFile? photo = await _picker.pickVideo(source: ImageSource.camera);
    if (photo != null) {
      _imageSubmitted(photo.path);
    }
  }

  Future<void> _inputMentionEvent() async {
    var context = getContext();
    var s = S.of(context);
    var value = await TextInputAndSearchDialog.show(
      context,
      s.Search,
      s.Please_input_event_id,
      SearchMentionEventComponent(),
      hintText: s.Note_Id,
    );
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
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      editorController.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.mention_event, value), null);

      editorController.moveCursorToPosition(index + 1);
    }
  }

  Future<void> _inputMentionUser() async {
    var context = getContext();
    var s = S.of(context);
    var value = await TextInputAndSearchDialog.show(
      context,
      s.Search,
      s.Please_input_user_pubkey,
      SearchMentionUserComponent(),
      hintText: s.User_Pubkey,
    );
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
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      editorController.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.mention_user, value), null);

      editorController.moveCursorToPosition(index + 1);
    }
  }

  Future<void> _inputLnbc() async {
    var context = getContext();
    var value = await TextInputAndSearchDialog.show(
      context,
      S.of(context).Input_Sats_num,
      S.of(context).Please_input_lnbc_text,
      GenLnbcComponent(),
      hintText: "lnbc...",
    );
    if (StringUtil.isNotBlank(value)) {
      _lnbcSubmitted(value);
    }
  }

  void _lnbcSubmitted(String? value) {
    if (value != null && value.isNotEmpty) {
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      editorController.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.lnbc, value), null);

      editorController.moveCursorToPosition(index + 1);
    }
  }

  Future<void> _inputTag() async {
    var context = getContext();
    var value = await TextInputDialog.show(
        context, S.of(context).Please_input_Topic_text,
        valueCheck: baseInputCheck, hintText: S.of(context).Topic);
    if (StringUtil.isNotBlank(value)) {
      _submitTag(value);
    }
  }

  bool baseInputCheck(BuildContext context, String value) {
    if (value.contains(" ")) {
      BotToast.showText(text: S.of(context).Text_can_t_contain_blank_space);
      return false;
    }
    if (value.contains("\n")) {
      BotToast.showText(text: S.of(context).Text_can_t_contain_new_line);
      return false;
    }
    return true;
  }

  void _submitTag(String? value) {
    var context = getContext();

    if (value != null && value.isNotEmpty) {
      final index = editorController.selection.baseOffset;
      final length = editorController.selection.extentOffset - index;

      editorController.replaceText(index, length,
          quill.CustomBlockEmbed(CustEmbedTypes.tag, value), null);

      editorController.moveCursorToPosition(index + 1);
    }
  }

  Future<Event?> doDocumentSave() async {
    var context = getContext();
    // dm agreement
    var agreement = getAgreement();
    // dm pubkey
    var pubkey = getPubkey();

    // customEmoji map
    Map<String, int> customEmojiMap = {};
    var tags = []..addAll(getTags());
    var tagsAddedWhenSend = []..addAll(getTagsAddedWhenSend());

    List<String> extralRelays = [];

    if (inputPoll) {
      var checkResult = pollInputController.checkInput(context);
      if (!checkResult) {
        return null;
      }
    }
    if (inputZapGoal) {
      var checkResult = zapGoalInputController.checkInput(context);
      if (!checkResult) {
        return null;
      }
    }

    var delta = editorController.document.toDelta();
    var operations = delta.toList();
    String result = "";
    for (var operation in operations) {
      if (operation.key == "insert") {
        if (operation.data is Map) {
          var m = operation.data as Map;
          var value = m["image"];
          if (StringUtil.isBlank(value)) {
            value = m["video"];
          }
          if (StringUtil.isNotBlank(value) && value is String) {
            if (value.indexOf("http") != 0) {
              // this is a local image, update it first
              var imagePath = await Uploader.upload(
                value,
                imageService: settingProvider.imageService,
              );
              if (StringUtil.isNotBlank(imagePath)) {
                value = imagePath;
              } else {
                BotToast.showText(text: S.of(context).Upload_fail);
                return null;
              }
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
            tags.add(["t", value]);
            continue;
          }

          value = m["mentionUser"];
          if (StringUtil.isNotBlank(value)) {
            if (!_lastIsSpace(result) && !_lastIsLineEnd(result)) {
              result += " ";
            }
            result += "nostr:${Nip19.encodePubKey(value)} ";

            // add user's read relays
            extralRelays.addAll(metadataProvider.getExtralRelays(value, false));
            continue;
          }

          value = m["mentionEvent"];
          if (StringUtil.isNotBlank(value)) {
            if (!_lastIsLineEnd(result)) {
              result += " ";
            }
            // if (agreement == null) {
            //   var relayAddr = "";
            //   var mentionEvent = singleEventProvider.getEvent(value);
            //   if (mentionEvent != null && mentionEvent.sources.isNotEmpty) {
            //     relayAddr = mentionEvent.sources[0];
            //   }
            //   tags.add(["e", value, relayAddr, "mention"]);
            //   var index = tags.length - 1;
            //   result += "#[$index] ";
            // } else {
            //   result += "nostr:${Nip19.encodeNoteId(value)} ";
            // }
            var mentionEvent = singleEventProvider.getEvent(value);
            if (mentionEvent != null && mentionEvent.sources.isNotEmpty) {
              List<String> relays = [];
              if (mentionEvent.sources.length > 3) {
                relays.add(mentionEvent.sources[0]);
                relays.add(mentionEvent.sources[1]);
                relays.add(mentionEvent.sources[2]);
              } else {
                relays.addAll(mentionEvent.sources);
              }
              var nevent = Nevent(
                  id: value, relays: relays, author: mentionEvent.pubKey);
              result += "${NIP19Tlv.encodeNevent(nevent)} ";
            } else {
              result += "nostr:${Nip19.encodeNoteId(value)} ";
            }
            continue;
          }

          value = m["customEmoji"];
          if (value != null && value is CustomEmoji) {
            result += ":${value.name}: ";

            if (customEmojiMap[value.name] == null) {
              customEmojiMap[value.name!] = 1;
              tags.add(["emoji", value.name, value.filepath]);
            }
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

    var subject = subjectController.text;
    if (StringUtil.isNotBlank(subject)) {
      allTags.add(["subject", subject]);
    }

    if (showWarning) {
      allTags.add(["content-warning", ""]);
    }

    Event? event;
    List<Event> extralEvents = [];
    if (agreement != null && StringUtil.isNotBlank(pubkey)) {
      if (openPrivateDM) {
        // Private dm message
        var rumorEvent = Event(nostr!.publicKey,
            kind.EventKind.PRIVATE_DIRECT_MESSAGE, allTags, result,
            publishAt: publishAt);
        // this is the event send to sender, should return after send and set into giftWrapProvider and dmProvider
        event = await GiftWrapUtil.getGiftWrapEvent(
            rumorEvent, nostr!, nostr!.publicKey);

        // private dm need to send message to all receiver. (sender and other receivers)
        for (var tags in allTags) {
          if (tags is List && tags.length > 1) {
            if (tags[0] == "p") {
              var extralEvent = await GiftWrapUtil.getGiftWrapEvent(
                  rumorEvent, nostr!, tags[1]);
              if (extralEvent != null) {
                extralEvents.add(extralEvent);
              }
            }
          }
        }
      } else {
        // dm message
        result = NIP04.encrypt(result, agreement, pubkey!);
        event = Event(
            nostr!.publicKey, kind.EventKind.DIRECT_MESSAGE, allTags, result,
            publishAt: publishAt);
      }
    } else if (inputPoll) {
      // poll event
      // get poll tag from PollInputComponentn
      var pollTags = pollInputController.getTags();
      allTags.addAll(pollTags);
      event = Event(nostr!.publicKey, kind.EventKind.POLL, allTags, result,
          publishAt: publishAt);
    } else if (inputZapGoal) {
      // zap goal event
      var extralTags = zapGoalInputController.getTags();
      allTags.addAll(extralTags);
      event = Event(nostr!.publicKey, kind.EventKind.ZAP_GOALS, allTags, result,
          publishAt: publishAt);
    } else {
      // text note
      event = Event(nostr!.publicKey, kind.EventKind.TEXT_NOTE, allTags, result,
          publishAt: publishAt);
    }

    if (event == null) {
      return null;
    }

    log(jsonEncode(event.toJson()));
    if (publishAt != null) {
      for (var extralEvent in extralEvents) {
        _handleSendingSendBoxEvent(extralEvent, extralRelays);
      }

      return _handleSendingSendBoxEvent(event, extralRelays);
    } else {
      for (var extralEvent in extralEvents) {
        _handleSendingEvent(extralEvent, extralRelays);
      }

      return _handleSendingEvent(event, extralRelays);
    }
  }

  Future<Event?> _handleSendingSendBoxEvent(
      Event e, List<String> extralRelays) async {
    if (StringUtil.isBlank(e.sig)) {
      nostr!.signEvent(e);
    }

    List<String> list = [...relayProvider.relayAddrs, ...extralRelays];
    for (var tag in e.tags) {
      if (tag is List && tag.length > 1) {
        var k = tag[0];
        var p = tag[1];
        if (k == "p") {
          list.addAll(metadataProvider.getExtralRelays(p, false));
        }
      }
    }
    list = list.toSet().toList();

    await SendBox.submit(e, list);

    return e;
  }

  Event? _handleSendingEvent(Event e, List<String> extralRelays) {
    List<String> list = [...extralRelays];
    for (var tag in e.tags) {
      if (tag is List && tag.length > 1) {
        var k = tag[0];
        var p = tag[1];
        if (k == "p") {
          list.addAll(metadataProvider.getExtralRelays(p, false));
        }
      }
    }
    list = list.toSet().toList();

    if (StringUtil.isNotBlank(e.sig)) {
      return nostr!.broadcase(e, tempRelays: list);
    } else {
      return nostr!.sendEvent(e, tempRelays: list);
    }
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

  void _inputPoll() {
    var targetValue = !inputPoll;
    _resetOthersInput();
    inputPoll = targetValue;
    updateUI();
  }

  void _inputGoal() {
    var targetValue = !inputZapGoal;
    _resetOthersInput();
    inputZapGoal = targetValue;
    updateUI();
  }

  void _resetOthersInput() {
    pollInputController.clear();
    zapGoalInputController.clear();

    inputPoll = false;
    inputZapGoal = false;
  }

  bool customEmojiShow = false;

  void customEmojiSelect() {
    FocusScope.of(getContext()).unfocus();
    customEmojiShow = true;
    emojiShow = false;
    updateUI();
  }

  Future<void> addCustomEmoji() async {
    var emoji = await CustomEmojiAddDialog.show(getContext());
    if (emoji != null) {
      listProvider.addCustomEmoji(emoji);
    }
  }

  void addEmojiToEditor(CustomEmoji emoji) {
    final index = editorController.selection.baseOffset;
    final length = editorController.selection.extentOffset - index;

    editorController.replaceText(
        index,
        length,
        quill.Embeddable(CustEmbedTypes.custom_emoji, emoji),
        TextSelection.collapsed(offset: index + 2),
        ignoreFocus: true);
    updateUI();
  }

  double emojiBtnWidth = 60;

  Widget buildEmojiListsWidget() {
    var context = getContext();
    var s = S.of(context);
    var themeData = Theme.of(context);
    var mainColor = themeData.primaryColor;
    var labelUnSelectColor = themeData.dividerColor;

    return Container(
      height: 260,
      padding: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
      width: double.infinity,
      child: Selector<ListProvider, Event?>(
        builder: (context, emojiEvent, child) {
          var emojiLists = listProvider.emojis(s, emojiEvent);

          List<Widget> tabBarList = [];
          List<Widget> tabBarViewList = [];

          var length = emojiLists.length;
          for (var index = 0; index < length; index++) {
            var emojiList = emojiLists[index];
            var isCustomEmoji = index == 0;

            tabBarList.add(Text(
              emojiList.key,
              overflow: TextOverflow.ellipsis,
            ));
            tabBarViewList.add(buildEmojiListWidget(
              emojiList.value,
              isCustomEmoji: isCustomEmoji,
            ));
          }

          var findMoreBtn = GestureDetector(
            onTap: () {
              WebViewRouter.open(context, "https://emojis-iota.vercel.app/");
            },
            child: Container(
              width: 40,
              child: Icon(Icons.search),
            ),
          );

          return DefaultTabController(
              length: tabBarList.length,
              child: Container(
                child: Column(
                  children: [
                    Container(
                      height: Base.TABBAR_HEIGHT,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: Base.TABBAR_HEIGHT,
                              child: TabBar(
                                tabs: tabBarList,
                                indicatorColor: mainColor,
                                labelColor: mainColor,
                                unselectedLabelColor: labelUnSelectColor,
                                isScrollable: true,
                              ),
                            ),
                          ),
                          findMoreBtn,
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(children: tabBarViewList),
                    ),
                  ],
                ),
              ));
        },
        selector: (context, _provider) {
          return _provider.getEmojiEvent();
        },
      ),
    );
  }

  Widget buildEmojiListWidget(List<CustomEmoji> emojis,
      {bool isCustomEmoji = false}) {
    List<Widget> list = [];

    if (isCustomEmoji) {
      list.add(GestureDetector(
        onTap: () {
          addCustomEmoji();
        },
        child: Container(
          width: emojiBtnWidth,
          height: emojiBtnWidth,
          child: const Icon(
            Icons.add,
            size: 50,
          ),
        ),
      ));
    }

    for (var emoji in emojis) {
      list.add(GestureDetector(
        onTap: () {
          addEmojiToEditor(emoji);
        },
        child: Container(
          // constraints:
          //     BoxConstraints(maxWidth: emojiBtnWidth, maxHeight: emojiBtnWidth),
          width: emojiBtnWidth,
          height: emojiBtnWidth,
          alignment: Alignment.center,
          child: ImageComponent(
            imageUrl: emoji.filepath!,
            placeholder: (context, url) => Container(),
          ),
        ),
      ));
    }

    var main = SingleChildScrollView(
      child: Wrap(
        // runAlignment: WrapAlignment.center,
        children: list,
        runSpacing: Base.BASE_PADDING_HALF,
        spacing: Base.BASE_PADDING_HALF,
      ),
    );

    return Container(
      height: 260,
      padding: EdgeInsets.only(left: Base.BASE_PADDING_HALF),
      width: double.infinity,
      child: main,
    );
  }

  bool showWarning = false;

  void _addWarning() {
    showWarning = !showWarning;
    updateUI();
  }

  bool showTitle = false;

  TextEditingController subjectController = TextEditingController();

  void _addTitle() {
    subjectController.clear();
    showTitle = !showTitle;
    updateUI();
  }

  Widget buildTitleWidget() {
    var themeData = Theme.of(getContext());
    var fontSize = themeData.textTheme.bodyLarge!.fontSize;
    var hintColor = themeData.hintColor;
    var s = S.of(getContext());

    return Container(
      // color: Colors.red,
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: AutoSizeTextField(
        maxLength: 80,
        controller: subjectController,
        textInputAction: TextInputAction.next,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: s.Please_input_title,
          border: InputBorder.none,
          hintStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
            color: hintColor.withOpacity(0.8),
          ),
          counterText: "",
        ),
      ),
    );
  }

  DateTime? publishAt;

  Future<void> selectedTime() async {
    var dt = await DatetimePickerComponent.show(getContext(),
        dateTime: publishAt != null ? publishAt : DateTime.now());
    publishAt = dt;
    updateUI();
  }
}
