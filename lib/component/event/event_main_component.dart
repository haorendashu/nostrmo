import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/component/content/content_video_component.dart';
import 'package:nostrmo/component/content/markdown/markdown_mention_event_element_builder.dart';
import 'package:nostrmo/util/platform_util.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

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
import '../../provider/setting_provider.dart';
import '../../util/router_util.dart';
import '../../util/string_util.dart';
import '../comfirm_dialog.dart';
import '../content/content_decoder.dart';
import '../content/content_image_component.dart';
import '../content/content_link_component.dart';
import '../content/content_tag_component.dart';
import '../content/markdown/markdown_mention_event_Inline_syntax.dart';
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
  });

  @override
  State<StatefulWidget> createState() {
    return _EventMainComponent();
  }
}

class _EventMainComponent extends State<EventMainComponent> {
  late EventRelation eventRelation;

  @override
  void initState() {
    super.initState();
    eventRelation = EventRelation.fromEvent(widget.event);
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

    Color? contentCardColor = themeData.cardColor;
    if (contentCardColor == Colors.white) {
      contentCardColor = Colors.grey[300];
    }

    Event? repostEvent;
    if (widget.event.kind == kind.EventKind.REPOST &&
        widget.event.content.contains("\"pubkey\"")) {
      try {
        var jsonMap = jsonDecode(widget.event.content);
        repostEvent = Event.fromJson(jsonMap);
      } catch (e) {
        print(e);
      }
    }

    List<Widget> list = [];
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
    } else if (widget.event.kind == kind.EventKind.REPOST) {
      list.add(Container(
        alignment: Alignment.centerLeft,
        child: Text("${s.Boost}:"),
      ));
      if (repostEvent != null) {
        list.add(EventQuoteComponent(
          event: repostEvent,
          showVideo: widget.showVideo,
        ));
      } else if (StringUtil.isNotBlank(eventRelation.rootId)) {
        list.add(EventQuoteComponent(
          id: eventRelation.rootId,
          showVideo: widget.showVideo,
        ));
      } else {
        list.add(
          buildContentWidget(_settingProvider, imagePreview, videoPreview),
        );
      }
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
            } else if (m.indexOf("video/") == 0 &&
                widget.showVideo &&
                !PlatformUtil.isPC()) {
              list.add(ContentVideoComponent(url: url!));
            } else {
              list.add(ContentLinkComponent(link: url!));
            }
          } else {
            var fileType = ContentDecoder.getPathType(url!);
            if (fileType == "image") {
              list.add(ContentImageComponent(imageUrl: url));
            } else if (fileType == "video" && !PlatformUtil.isPC()) {
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

      list.add(EventReactionsComponent(
        screenshotController: widget.screenshotController,
        event: widget.event,
        eventRelation: eventRelation,
        showDetailBtn: widget.showDetailBtn,
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EventTopComponent(
          event: widget.event,
          pagePubkey: widget.pagePubkey,
        ),
        Container(
          width: double.maxFinite,
          padding: const EdgeInsets.only(
            left: Base.BASE_PADDING,
            right: Base.BASE_PADDING,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: list,
          ),
        ),
      ],
    );
  }

  bool forceShowLongContnet = false;

  bool hideLongContent = false;

  Widget buildContentWidget(
      SettingProvider _settingProvider, bool imagePreview, bool videoPreview) {
    var main = Container(
      width: double.maxFinite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: ContentDecoder.decode(
          context,
          null,
          widget.event,
          textOnTap: widget.textOnTap,
          showImage: imagePreview,
          showVideo: videoPreview,
          showLinkPreview: _settingProvider.linkPreview == OpenStatus.OPEN,
          imageListMode: widget.imageListMode,
        ),
      ),
    );

    return main;
  }

  buildMarkdownWidget(ThemeData themeData) {
    return MarkdownBody(
      data: widget.event.content,
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
          String nip19Name = Nip19.encodeSimplePubKey(widget.pubkey);
          String displayName = "";

          if (metadata != null) {
            if (StringUtil.isNotBlank(metadata.displayName)) {
              displayName = metadata.displayName!;
            } else if (StringUtil.isNotBlank(metadata.name)) {
              displayName = metadata.name!;
            }
          }

          if (StringUtil.isBlank(displayName)) {
            displayName = nip19Name;
          }

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
