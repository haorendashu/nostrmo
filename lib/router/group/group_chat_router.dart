import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_mem_box.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/nip29/group_metadata.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/component/group_identifier_inherited_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/provider/group_details_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../component/appbar_back_btn_component.dart';
import '../../component/editor/custom_emoji_embed_builder.dart';
import '../../component/editor/editor_mixin.dart';
import '../../component/editor/lnbc_embed_builder.dart';
import '../../component/editor/mention_event_embed_builder.dart';
import '../../component/editor/mention_user_embed_builder.dart';
import '../../component/editor/pic_embed_builder.dart';
import '../../component/editor/tag_embed_builder.dart';
import '../../component/editor/video_embed_builder.dart';
import '../../component/event/simple_event_component.dart';
import '../../component/user/name_component.dart';
import '../../component/user/user_pic_component.dart';
import '../../consts/base.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/group_provider.dart';
import '../../util/load_more_event.dart';
import '../dm/dm_detail_item_component.dart';

class GroupChatRouter extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _GroupChatRouter();
  }
}

class _GroupChatRouter extends CustState<GroupChatRouter>
    with EditorMixin, LoadMoreEvent {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ScrollOffsetListener scrollOffsetListener =
      ScrollOffsetListener.create();

  GroupIdentifier? groupIdentifier;

  EventMemBox? eventBox;

  @override
  void initState() {
    super.initState();
    bindLoadMoreItemScroll(itemPositionsListener);
  }

  @override
  Future<void> onReady(BuildContext context) async {
    if (groupIdentifier != null) {
      if (groupDetailsProvider.getChatsEventBox(groupIdentifier!) == null) {
        groupDetailsProvider.queryGroupEvents(
            groupIdentifier!,
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            GroupDetailsProvider.supportChatKinds);
      }
    }
  }

  Event? replingEvent;

  @override
  Widget doBuild(BuildContext context) {
    var themeData = Theme.of(context);
    var textColor = themeData.textTheme.bodyMedium!.color;
    var cardColor = themeData.cardColor;
    var s = S.of(context);

    var groupIdentifierItf = RouterUtil.routerArgs(context);
    if (groupIdentifierItf == null && groupIdentifierItf is! GroupIdentifier) {
      return Container();
    }
    groupIdentifier = groupIdentifierItf as GroupIdentifier;

    var groupAdmins = groupProvider.getAdmins(groupIdentifier!);

    var nameComponnet = Selector<GroupProvider, GroupMetadata?>(
      builder: (BuildContext context, GroupMetadata? value, Widget? child) {
        String text = groupIdentifier!.groupId;
        if (value != null && StringUtil.isNotBlank(value.name)) {
          text = value.name!;
        }

        return Text(
          text,
          style: TextStyle(
            fontSize: themeData.textTheme.bodyLarge!.fontSize,
            fontWeight: FontWeight.bold,
          ),
        );
      },
      selector: (context, _provider) {
        return _provider.getMetadata(groupIdentifier!);
      },
    );

    var localPubkey = nostr!.publicKey;

    List<Widget> list = [];

    var listWidget = Selector<GroupDetailsProvider, EventMemBox?>(
        builder: (context, _eventBox, child) {
      if (_eventBox == null) {
        return Container();
      }
      eventBox = _eventBox;
      preBuild();

      return ScrollablePositionedList.builder(
        itemBuilder: (context, index) {
          var event = eventBox!.get(index);
          if (event == null) {
            return Container();
          }

          return DMDetailItemComponent(
            sessionPubkey: event.pubkey,
            event: event,
            isLocal: localPubkey == event.pubkey,
            onLongPress: () {
              setState(() {
                replingEvent = event;
              });
            },
            onRepledEventTap: (replingEventId) {
              if (eventBox == null) {
                return null;
              }

              var list = eventBox!.all();
              for (var index = 0; index < list.length; index++) {
                var event = list[index];
                if (event.id == replingEventId) {
                  itemScrollController.jumpTo(index: index);
                }
              }
            },
          );
        },
        reverse: true,
        itemCount: eventBox!.length(),
        // dragStartBehavior: DragStartBehavior.down,
        // controller: _controller,
        itemScrollController: itemScrollController,
        scrollOffsetController: scrollOffsetController,
        itemPositionsListener: itemPositionsListener,
        scrollOffsetListener: scrollOffsetListener,
      );
    }, selector: (context, provider) {
      return provider.getChatsEventBox(groupIdentifier!);
    });

    list.add(Expanded(
      child: Container(
        margin: const EdgeInsets.only(
          bottom: Base.BASE_PADDING,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: listWidget,
            ),
            Selector<GroupProvider, int>(builder: (context, memberShip, child) {
              if (memberShip == GroupMembership.MEMBER ||
                  memberShip == GroupMembership.ADMIN) {
                return Container();
              }

              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: joinGroup,
                  child: buildTopAlertWidget(s.Join_group_notice),
                ),
              );
            }, selector: (context, _provider) {
              return _provider.checkMembership(
                  groupIdentifier!, nostr!.publicKey);
            }),
            Selector<ListProvider, bool>(builder: (context, value, child) {
              if (value) {
                return Container();
              }

              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: addGroup,
                  child: buildTopAlertWidget(s.Add_group_notice),
                ),
              );
            }, selector: (context, _provider) {
              return _provider.containGroups(groupIdentifier!);
            }),
          ],
        ),
      ),
    ));

    Widget editorWidget = Row(
      children: [
        Expanded(
          child: QuillEditor(
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
              padding: EdgeInsets.only(
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
              ),
              maxHeight: 300,
            ),
            scrollController: ScrollController(),
            focusNode: focusNode,
            controller: editorController,
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
    );

    if (replingEvent != null) {
      editorWidget = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(
              top: Base.BASE_PADDING,
              left: Base.BASE_PADDING,
              right: Base.BASE_PADDING,
            ),
            child: Row(
              children: [
                Text("${s.Replying}  "),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(Base.BASE_PADDING_HALF),
                    decoration: BoxDecoration(
                      color: themeData.hintColor.withAlpha(100),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SimpleEventComponent(replingEvent!),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      replingEvent = null;
                    });
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    padding: EdgeInsets.all(Base.BASE_PADDING_HALF),
                    child: Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
          editorWidget,
        ],
      );
    }

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
      child: editorWidget,
    ));

    list.add(buildEditorBtns(showShadow: false, height: null));
    if (emojiShow) {
      list.add(buildEmojiSelector());
    }
    if (customEmojiShow) {
      list.add(buildEmojiListsWidget());
    }

    Widget main = Container(
      width: double.maxFinite,
      height: double.maxFinite,
      child: Column(children: list),
    );

    return Scaffold(
      appBar: AppBar(
        leading: AppbarBackBtnComponent(),
        title: nameComponnet,
        actions: [
          GestureDetector(
            onTap: () {
              RouterUtil.router(
                  context, RouterPath.GROUP_NOTE_LIST, groupIdentifier);
            },
            behavior: HitTestBehavior.translucent,
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              child: Image.asset(
                "assets/imgs/nostr.png",
                width: 23,
                height: 23,
              ),
            ),
          ),
        ],
      ),
      body: GroupIdentifierInheritedWidget(
        groupIdentifier: groupIdentifier!,
        groupAdmins: groupAdmins,
        child: main,
      ),
    );
  }

  Widget buildTopAlertWidget(String title) {
    return Container(
      height: 30,
      width: double.infinity,
      margin: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
        top: Base.BASE_PADDING,
      ),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white,
        ),
      ),
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
      replingEvent = null;
      setState(() {});
    } finally {
      cancelFunc.call();
    }
  }

  void removeQuotingEvent() {
    setState(() {
      replingEvent = null;
    });
  }

  @override
  GroupIdentifier? getGroupIdentifier() {
    return groupIdentifier;
  }

  @override
  int? getGroupEventKind() {
    return EventKind.GROUP_CHAT_MESSAGE;
  }

  @override
  BuildContext getContext() {
    return context;
  }

  @override
  String? getPubkey() {
    return null;
  }

  @override
  List getTags() {
    if (replingEvent != null) {
      return [
        ["q", replingEvent!.id, "", replingEvent!.pubkey],
      ];
    }
    return [];
  }

  @override
  List getTagsAddedWhenSend() {
    if (eventBox == null) {
      return [];
    }

    List<dynamic> tags = [];
    var previous = GroupDetailsProvider.getTimelinePrevious(eventBox!);
    if (previous.isNotEmpty) {
      var previousTag = ["previous", ...previous];
      tags.add(previousTag);
    }
    return tags;
  }

  @override
  bool isDM() {
    return false;
  }

  @override
  void updateUI() {
    setState(() {});
  }

  @override
  void doQuery() async {
    preQuery();

    if (eventBox != null && groupIdentifier != null && until != null) {
      groupDetailsProvider.queryGroupEvents(
          groupIdentifier!, until!, GroupDetailsProvider.supportChatKinds);
    }
  }

  @override
  EventMemBox getEventBox() {
    return eventBox!;
  }

  void joinGroup() {
    if (groupIdentifier != null) {
      listProvider.joinAndAddGroup(groupIdentifier!);
    }
  }

  void addGroup() {
    if (groupIdentifier != null) {
      listProvider.addGroup(groupIdentifier!);
    }
  }
}
