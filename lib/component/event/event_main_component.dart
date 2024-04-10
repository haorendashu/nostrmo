import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:nostrmo/component/content/content_video_component.dart';
import 'package:nostrmo/component/content/markdown/markdown_mention_event_element_builder.dart';
import 'package:nostrmo/component/event/event_zap_goals_component.dart';
import 'package:nostrmo/component/name_component.dart';
import 'package:nostrmo/component/simple_name_component.dart';
import 'package:nostrmo/consts/base64.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../client/event.dart';
import '../../client/event_kind.dart' as kind;
import '../../client/event_relation.dart';
import '../../client/nip23/long_form_info.dart';
import '../../client/nip19/nip19.dart';
import '../../client/nip19/nip19_tlv.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../consts/router_path.dart';
import '../../data/metadata.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/metadata_provider.dart';
import '../../provider/replaceable_event_provider.dart';
import '../../provider/setting_provider.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';
import '../comfirm_dialog.dart';
import '../content/content_component.dart';
import '../content/content_decoder.dart';
import '../content/content_image_component.dart';
import '../content/content_link_component.dart';
import '../content/content_tag_component.dart';
import '../content/markdown/markdown_mention_event_inline_syntax.dart';
import '../content/markdown/markdown_mention_user_element_builder.dart';
import '../content/markdown/markdown_mention_user_inline_syntax.dart';
import '../content/markdown/markdown_nevent_inline_syntax.dart';
import '../content/markdown/markdown_nprofile_inline_syntax.dart';
import '../content/markdown/markdown_nrelay_element_builder.dart';
import '../content/markdown/markdown_nrelay_inline_syntax copy.dart';
import 'event_poll_component.dart';
import '../webview_router.dart';
import 'event_quote_component.dart';
import 'event_reactions_component.dart';
import 'event_top_component.dart';

class EventMainComponent extends StatefulWidget {
  ScreenshotController screenshotController;

  Event event;

  String? pagePubkey;

  bool showReplying;

  Function? textOnTap;

  bool showVideo;

  bool imageListMode;

  bool showDetailBtn;

  bool showLongContent;

  bool showSubject;

  bool showCommunity;

  EventRelation? eventRelation;

  bool showLinkedLongForm;

  EventMainComponent({
    super.key,
    required this.screenshotController,
    required this.event,
    this.pagePubkey,
    this.showReplying = true,
    this.textOnTap,
    this.showVideo = false,
    this.imageListMode = false,
    this.showDetailBtn = true,
    this.showLongContent = false,
    this.showSubject = true,
    this.showCommunity = true,
    this.eventRelation,
    this.showLinkedLongForm = true,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventMainComponent();
  }
}

class _EventMainComponent extends State<EventMainComponent> {
  bool showWarning = false;

  late EventRelation eventRelation;

  @override
  void initState() {
    super.initState();
    if (widget.eventRelation == null) {
      eventRelation = EventRelation.fromEvent(widget.event);
    } else {
      eventRelation = widget.eventRelation!;
    }
  }

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var _settingProvider = Provider.of<SettingProvider>(context);
    if (eventRelation.id != widget.event.id) {
      // change when thead root load lazy
      eventRelation = EventRelation.fromEvent(widget.event);
    }

    bool imagePreview = _settingProvider.imagePreview == null ||
        _settingProvider.imagePreview == OpenStatus.OPEN;
    bool videoPreview = widget.showVideo;
    if (_settingProvider.videoPreview != null) {
      videoPreview = _settingProvider.videoPreview == OpenStatus.OPEN;
    }

    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    var largeTextSize = themeData.textTheme.bodyLarge!.fontSize;
    var mainColor = themeData.primaryColor;

    Color? contentCardColor = themeData.cardColor;
    if (contentCardColor == Colors.white) {
      contentCardColor = Colors.grey[300];
    }

    Event? repostEvent;
    if ((widget.event.kind == kind.EventKind.REPOST ||
            widget.event.kind == kind.EventKind.GENERIC_REPOST) &&
        widget.event.content.contains("\"pubkey\"")) {
      try {
        var jsonMap = jsonDecode(widget.event.content);
        repostEvent = Event.fromJson(jsonMap);

        // set source to repost event
        if (repostEvent.id == eventRelation.rootId &&
            StringUtil.isNotBlank(eventRelation.rootRelayAddr)) {
          repostEvent.sources.add(eventRelation.rootRelayAddr!);
        } else if (repostEvent.id == eventRelation.replyId &&
            StringUtil.isNotBlank(eventRelation.replyRelayAddr)) {
          repostEvent.sources.add(eventRelation.replyRelayAddr!);
        }
      } catch (e) {
        print(e);
      }
    }

    if (_settingProvider.autoOpenSensitive == OpenStatus.OPEN) {
      showWarning = true;
    }

    List<Widget> list = [];
    if (showWarning || !eventRelation.warning) {
      if (widget.event.kind == kind.EventKind.LONG_FORM) {
        var longFormMargin = EdgeInsets.only(bottom: Base.BASE_PADDING_HALF);

        List<Widget> subList = [];
        var longFormInfo = LongFormInfo.fromEvent(widget.event);
        if (StringUtil.isNotBlank(longFormInfo.title)) {
          subList.add(
            Container(
              margin: longFormMargin,
              child: Text(
                longFormInfo.title!,
                maxLines: 10,
                style: TextStyle(
                  fontSize: largeTextSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
        if (longFormInfo.topics.isNotEmpty) {
          List<Widget> topicWidgets = [];
          for (var topic in longFormInfo.topics) {
            topicWidgets.add(ContentTagComponent(tag: "#$topic"));
          }

          subList.add(Container(
            margin: longFormMargin,
            child: Wrap(
              spacing: Base.BASE_PADDING_HALF,
              runSpacing: Base.BASE_PADDING_HALF / 2,
              children: topicWidgets,
            ),
          ));
        }
        if (StringUtil.isNotBlank(longFormInfo.summary)) {
          Widget summaryTextWidget = Text(
            longFormInfo.summary!,
            style: TextStyle(
              color: hintColor,
            ),
          );
          subList.add(
            Container(
              width: double.infinity,
              margin: longFormMargin,
              child: summaryTextWidget,
            ),
          );
        }
        if (StringUtil.isNotBlank(longFormInfo.image)) {
          subList.add(Container(
            margin: longFormMargin,
            child: ContentImageComponent(
              imageUrl: longFormInfo.image!,
            ),
          ));
        }

        list.add(
          Container(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: subList,
            ),
          ),
        );

        if (widget.showLongContent) {
          var markdownWidget = buildMarkdownWidget(themeData);

          list.add(Container(
            width: double.infinity,
            child: RepaintBoundary(child: markdownWidget),
          ));
        }

        list.add(EventReactionsComponent(
          screenshotController: widget.screenshotController,
          event: widget.event,
          eventRelation: eventRelation,
          showDetailBtn: widget.showDetailBtn,
        ));
      } else if (widget.event.kind == kind.EventKind.REPOST ||
          widget.event.kind == kind.EventKind.GENERIC_REPOST) {
        list.add(Container(
          alignment: Alignment.centerLeft,
          child: Text("${s.Boost}:"),
        ));
        if (repostEvent != null) {
          list.add(EventQuoteComponent(
            event: repostEvent,
            showVideo: widget.showVideo,
          ));
        } else {
          var rootId = eventRelation.rootId;
          var rootRelayAddr = eventRelation.rootRelayAddr;
          if (StringUtil.isBlank(rootId)) {
            // rootId can't find, try to find any e tag.
            for (var tag in widget.event.tags) {
              if (tag.length > 1) {
                var k = tag[0];
                var v = tag[1];

                if (k == "e") {
                  rootId = v;
                  if (tag.length > 2 && tag[2] != "") {
                    rootRelayAddr = tag[2];
                  }
                  break;
                }
              }
            }
          }

          if (StringUtil.isNotBlank(rootId)) {
            list.add(EventQuoteComponent(
              id: rootId,
              eventRelayAddr: rootRelayAddr,
              showVideo: widget.showVideo,
            ));
          } else {
            list.add(
              buildContentWidget(_settingProvider, imagePreview, videoPreview),
            );
          }
        }

        // list.add(EventReactionsComponent(
        //   screenshotController: widget.screenshotController,
        //   event: widget.event,
        //   eventRelation: eventRelation,
        //   showDetailBtn: widget.showDetailBtn,
        // ));
      } else if (widget.event.kind == kind.EventKind.SHARED_FILE) {
        list.add(buildSharedFileWidget());
        list.add(EventReactionsComponent(
          screenshotController: widget.screenshotController,
          event: widget.event,
          eventRelation: eventRelation,
          showDetailBtn: widget.showDetailBtn,
        ));
      } else {
        if (widget.showReplying && eventRelation.tagPList.isNotEmpty) {
          var textStyle = TextStyle(
            color: hintColor,
            fontSize: smallTextSize,
          );
          List<Widget> replyingList = [];
          var length = eventRelation.tagPList.length;
          replyingList.add(Text(
            "${s.Replying}: ",
            style: textStyle,
          ));
          for (var index = 0; index < length; index++) {
            var p = eventRelation.tagPList[index];
            var isLast = index < length - 1 ? false : true;
            replyingList.add(EventReplyingcomponent(pubkey: p));
            if (!isLast) {
              replyingList.add(Text(
                " & ",
                style: textStyle,
              ));
            }
          }
          list.add(Container(
            width: double.maxFinite,
            padding: const EdgeInsets.only(
              bottom: Base.BASE_PADDING_HALF,
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: replyingList,
            ),
          ));
        } else {
          // hide the reply note subject!
          if (widget.showSubject) {
            if (StringUtil.isNotBlank(eventRelation.subject)) {
              list.add(Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.only(bottom: Base.BASE_PADDING_HALF),
                child: Text(
                  eventRelation.subject!,
                  maxLines: 10,
                  style: TextStyle(
                    fontSize: largeTextSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ));
            }
          }
        }

        list.add(
          buildContentWidget(_settingProvider, imagePreview, videoPreview),
        );

        if (widget.event.kind == kind.EventKind.POLL) {
          list.add(EventPollComponent(
            event: widget.event,
          ));
        } else if (widget.event.kind == kind.EventKind.ZAP_GOALS ||
            StringUtil.isNotBlank(eventRelation.zapraiser)) {
          list.add(EventZapGoalsComponent(
            event: widget.event,
          ));
        }

        if (widget.event.kind == kind.EventKind.FILE_HEADER) {
          String? m;
          String? url;
          for (var tag in widget.event.tags) {
            if (tag.length > 1) {
              var key = tag[0];
              var value = tag[1];
              if (key == "url") {
                url = value;
              } else if (key == "m") {
                m = value;
              }
            }
          }

          if (StringUtil.isNotBlank(url)) {
            //  show and decode depend m
            if (StringUtil.isNotBlank(m)) {
              if (m!.indexOf("image/") == 0) {
                list.add(ContentImageComponent(imageUrl: url!));
              } else if (m.indexOf("video/") == 0 && widget.showVideo) {
                list.add(ContentVideoComponent(url: url!));
              } else {
                list.add(ContentLinkComponent(link: url!));
              }
            } else {
              var fileType = ContentDecoder.getPathType(url!);
              if (fileType == "image") {
                list.add(ContentImageComponent(imageUrl: url));
              } else if (fileType == "video") {
                if (settingProvider.videoPreview != OpenStatus.OPEN &&
                    (settingProvider.videoPreviewInList == OpenStatus.OPEN ||
                        widget.showVideo)) {
                  list.add(ContentVideoComponent(url: url));
                } else {
                  list.add(ContentLinkComponent(link: url));
                }
              } else {
                list.add(ContentLinkComponent(link: url));
              }
            }
          }
        }

        if (eventRelation.aId != null &&
            eventRelation.aId!.kind == kind.EventKind.LONG_FORM &&
            widget.showLinkedLongForm) {
          list.add(EventQuoteComponent(
            aId: eventRelation.aId!,
          ));
        }

        if (widget.event.kind != kind.EventKind.ZAP) {
          list.add(EventReactionsComponent(
            screenshotController: widget.screenshotController,
            event: widget.event,
            eventRelation: eventRelation,
            showDetailBtn: widget.showDetailBtn,
          ));
        } else {
          list.add(Container(
            height: Base.BASE_PADDING,
          ));
        }
      }
    } else {
      list.add(buildWarningWidget(largeTextSize!, mainColor));
    }

    List<Widget> eventAllList = [];

    if (eventRelation.aId != null &&
        eventRelation.aId!.kind == kind.EventKind.COMMUNITY_DEFINITION &&
        widget.showCommunity) {
      var communityTitle = Row(
        children: [
          Icon(
            Icons.groups,
            size: largeTextSize,
            color: hintColor,
          ),
          Container(
            margin: EdgeInsets.only(
              left: Base.BASE_PADDING_HALF,
              right: 3,
            ),
            child: Text(
              s.From,
              style: TextStyle(
                color: hintColor,
                fontSize: smallTextSize,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              RouterUtil.router(
                  context, RouterPath.COMMUNITY_DETAIL, eventRelation.aId);
            },
            child: Text(
              eventRelation.aId!.title,
              style: TextStyle(
                fontSize: smallTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );

      eventAllList.add(Container(
        padding: const EdgeInsets.only(
          left: Base.BASE_PADDING + 4,
          right: Base.BASE_PADDING + 4,
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: communityTitle,
      ));
    }

    eventAllList.add(EventTopComponent(
      event: widget.event,
      pagePubkey: widget.pagePubkey,
    ));

    eventAllList.add(Container(
      width: double.maxFinite,
      padding: const EdgeInsets.only(
        left: Base.BASE_PADDING,
        right: Base.BASE_PADDING,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: eventAllList,
    );
  }

  bool forceShowLongContnet = false;

  bool hideLongContent = false;

  Widget buildContentWidget(
      SettingProvider _settingProvider, bool imagePreview, bool videoPreview) {
    var main = Container(
      width: double.maxFinite,
      child: ContentComponent(
        content: widget.event.content,
        event: widget.event,
        textOnTap: widget.textOnTap,
        showImage: imagePreview,
        showVideo: videoPreview,
        showLinkPreview: _settingProvider.linkPreview == OpenStatus.OPEN,
        imageListMode: widget.imageListMode,
      ),
      // child: Column(
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   mainAxisSize: MainAxisSize.min,
      //   children: ContentDecoder.decode(
      //     context,
      //     null,
      //     widget.event,
      //     textOnTap: widget.textOnTap,
      //     showImage: imagePreview,
      //     showVideo: videoPreview,
      //     showLinkPreview: _settingProvider.linkPreview == OpenStatus.OPEN,
      //     imageListMode: widget.imageListMode,
      //   ),
      // ),
    );

    return main;
  }

  buildMarkdownWidget(ThemeData themeData) {
    // handle old mention, replace to NIP-27 style: nostr:note1xxxx or nostr:npub1xxx
    var content = widget.event.content;
    var tagLength = widget.event.tags.length;
    for (var i = 0; i < tagLength; i++) {
      var tag = widget.event.tags[i];
      String? link;

      if (tag is List && tag.length > 1) {
        var key = tag[0];
        var value = tag[1];
        if (key == "e") {
          link = "nostr:${Nip19.encodeNoteId(value)}";
        } else if (key == "p") {
          link = "nostr:${Nip19.encodePubKey(value)}";
        }
      }

      if (StringUtil.isNotBlank(link)) {
        content = content.replaceAll("#[$i]", link!);
      }
    }

    return MarkdownBody(
      data: content,
      selectable: true,
      builders: {
        MarkdownMentionUserElementBuilder.TAG:
            MarkdownMentionUserElementBuilder(),
        MarkdownMentionEventElementBuilder.TAG:
            MarkdownMentionEventElementBuilder(),
        MarkdownNrelayElementBuilder.TAG: MarkdownNrelayElementBuilder(),
      },
      blockSyntaxes: [],
      inlineSyntaxes: [
        MarkdownMentionEventInlineSyntax(),
        MarkdownMentionUserInlineSyntax(),
        MarkdownNeventInlineSyntax(),
        MarkdownNprofileInlineSyntax(),
        MarkdownNrelayInlineSyntax(),
      ],
      imageBuilder: (Uri uri, String? title, String? alt) {
        if (settingProvider.imagePreview == OpenStatus.CLOSE) {
          return ContentLinkComponent(
            link: uri.toString(),
            title: title,
          );
        }
        return ContentImageComponent(imageUrl: uri.toString());
      },
      styleSheet: MarkdownStyleSheet(
        a: TextStyle(
          color: themeData.primaryColor,
          decoration: TextDecoration.underline,
        ),
      ),
      onTapLink: (String text, String? href, String title) async {
        // print("text $text href $href title $title");
        if (StringUtil.isNotBlank(href)) {
          if (href!.indexOf("http") == 0) {
            WebViewRouter.open(context, href);
          } else if (href.indexOf("nostr:") == 0) {
            var link = href.replaceFirst("nostr:", "");
            if (Nip19.isPubkey(link)) {
              // jump user page
              var pubkey = Nip19.decode(link);
              if (StringUtil.isNotBlank(pubkey)) {
                RouterUtil.router(context, RouterPath.USER, pubkey);
              }
            } else if (NIP19Tlv.isNprofile(link)) {
              var nprofile = NIP19Tlv.decodeNprofile(link);
              if (nprofile != null) {
                RouterUtil.router(context, RouterPath.USER, nprofile.pubkey);
              }
            } else if (Nip19.isNoteId(link)) {
              var noteId = Nip19.decode(link);
              if (StringUtil.isNotBlank(noteId)) {
                RouterUtil.router(context, RouterPath.EVENT_DETAIL, noteId);
              }
            } else if (NIP19Tlv.isNevent(link)) {
              var nevent = NIP19Tlv.decodeNevent(link);
              if (nevent != null) {
                RouterUtil.router(context, RouterPath.EVENT_DETAIL, nevent.id);
              }
            } else if (NIP19Tlv.isNaddr(link)) {
              var naddr = NIP19Tlv.decodeNaddr(link);
              if (naddr != null) {
                RouterUtil.router(context, RouterPath.EVENT_DETAIL, naddr.id);
              }
            } else if (NIP19Tlv.isNrelay(link)) {
              var nrelay = NIP19Tlv.decodeNrelay(link);
              if (nrelay != null) {
                var result = await ComfirmDialog.show(
                    context, S.of(context).Add_this_relay_to_local);
                if (result == true) {
                  relayProvider.addRelay(nrelay.addr);
                }
              }
            }
          }
        }
      },
    );
  }

  Widget buildWarningWidget(double largeTextSize, Color mainColor) {
    var s = S.of(context);

    return Container(
      margin:
          EdgeInsets.only(bottom: Base.BASE_PADDING, top: Base.BASE_PADDING),
      width: double.maxFinite,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning),
              Container(
                margin: EdgeInsets.only(left: Base.BASE_PADDING_HALF),
                child: Text(
                  s.Content_warning,
                  style: TextStyle(fontSize: largeTextSize),
                ),
              )
            ],
          ),
          Text(s.This_note_contains_sensitive_content),
          GestureDetector(
            onTap: () {
              setState(() {
                showWarning = true;
              });
            },
            child: Container(
              margin: EdgeInsets.only(top: Base.BASE_PADDING_HALF),
              padding: const EdgeInsets.only(
                top: 4,
                bottom: 4,
                left: Base.BASE_PADDING,
                right: Base.BASE_PADDING,
              ),
              decoration: BoxDecoration(
                color: mainColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                s.Show,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSharedFileWidget() {
    var content = widget.event.content;
    var type = widget.eventRelation!.type;

    if (!content.startsWith(BASE64.PREFIX)) {
      content = BASE64.PREFIX + content;
    }

    if (type != null && type.startsWith("image")) {
      return ContentImageComponent(
        imageUrl: content,
      );
    } else if (type != null && type.startsWith("video")) {
      return ContentVideoComponent(
        url: content,
      );
    } else {
      log("buildSharedFileWidget not support type $type");
      return ContentComponent(
        content: widget.event.content,
        event: widget.event,
      );
    }
  }
}

class EventReplyingcomponent extends StatefulWidget {
  String pubkey;

  EventReplyingcomponent({required this.pubkey});

  @override
  State<StatefulWidget> createState() {
    return _EventReplyingcomponent();
  }
}

class _EventReplyingcomponent extends State<EventReplyingcomponent> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.USER, widget.pubkey);
      },
      child: Selector<MetadataProvider, Metadata?>(
        builder: (context, metadata, child) {
          var themeData = Theme.of(context);
          var hintColor = themeData.hintColor;
          var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
          var displayName =
              SimpleNameComponent.getSimpleName(widget.pubkey, metadata);

          return Text(
            displayName,
            style: TextStyle(
              color: hintColor,
              fontSize: smallTextSize,
              // fontWeight: FontWeight.bold,
            ),
          );
        },
        selector: (context, _provider) {
          return _provider.getMetadata(widget.pubkey);
        },
      ),
    );
  }
}
