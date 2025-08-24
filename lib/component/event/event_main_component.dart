import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart' as mdw;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/event_relation.dart';
import 'package:nostr_sdk/nip19/nip19.dart';
import 'package:nostr_sdk/nip19/nip19_tlv.dart';
import 'package:nostr_sdk/nip23/long_form_info.dart';
import 'package:nostr_sdk/nip35/torrent_info.dart';
import 'package:nostr_sdk/nip51/follow_set.dart';
import 'package:nostr_sdk/utils/path_type_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/content/content_video_component.dart';
import 'package:nostrmo/component/content/markdown/markdown_mention_event_element_builder.dart';
import 'package:nostrmo/component/content/markdown/mdw/mdw_nrelay_node.dart';
import 'package:nostrmo/component/event/event_torrent_component.dart';
import 'package:nostrmo/component/event/event_zap_goals_component.dart';
import 'package:nostrmo/component/follow_set_card_component.dart';
import 'package:nostrmo/component/user/name_component.dart';
import 'package:nostrmo/component/user/simple_name_component.dart';
import 'package:nostrmo/component/user/user_pic_component.dart';
import 'package:nostrmo/consts/base64.dart';
import 'package:nostrmo/provider/single_event_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

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
import '../confirm_dialog.dart';
import '../content/content_component.dart';
import '../content/content_decoder.dart';
import '../content/content_image_component.dart';
import '../content/content_link_component.dart';
import '../content/content_tag_component.dart';
import '../content/markdown/markdown_mention_event_inline_syntax.dart';
import '../content/markdown/markdown_mention_user_element_builder.dart';
import '../content/markdown/markdown_mention_user_inline_syntax.dart';
import '../content/markdown/markdown_naddr_inline_syntax.dart';
import '../content/markdown/markdown_nevent_inline_syntax.dart';
import '../content/markdown/markdown_nprofile_inline_syntax.dart';
import '../content/markdown/markdown_nrelay_element_builder.dart';
import '../content/markdown/markdown_nrelay_inline_syntax copy.dart';
import '../content/markdown/mdw/mdw_mention_event_node.dart';
import '../content/markdown/mdw/mdw_mention_user_node.dart';
import '../image_component.dart';
import '../zap/zap_split_icon_component.dart';
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

  bool inQuote;

  bool traceMode;

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
    this.inQuote = false,
    this.traceMode = false,
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
    try {
      return doBuild(context);
    } catch (e, stacktrace) {
      print(e.toString());
      print(stacktrace.toString());
      return Container();
    }
  }

  @override
  Widget doBuild(BuildContext context) {
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

    Event? repostEvent;
    if (widget.event.kind == EventKind.STARTER_PACKS ||
        widget.event.kind == EventKind.MEDIA_STARTER_PACKS) {
      var followSet = FollowSet.getPublicFollowSet(widget.event);
      return FollowSetCardComponent(followSet);
    } else if ((widget.event.kind == EventKind.REPOST ||
            widget.event.kind == EventKind.GENERIC_REPOST) &&
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
      if (widget.event.kind == EventKind.LONG_FORM) {
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

        if (widget.showLongContent &&
            StringUtil.isNotBlank(widget.event.content)) {
          var markdownWidget = buildMarkdownWidget(themeData);
          list.add(Container(
            width: double.infinity,
            child: RepaintBoundary(child: markdownWidget),
          ));
        }

        if (eventRelation.zapInfos.isNotEmpty) {
          list.add(buildZapInfoWidgets(themeData));
        }

        list.add(EventReactionsComponent(
          screenshotController: widget.screenshotController,
          event: widget.event,
          eventRelation: eventRelation,
          showDetailBtn: widget.showDetailBtn,
        ));
      } else if (widget.event.kind == EventKind.REPOST ||
          widget.event.kind == EventKind.GENERIC_REPOST) {
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
      } else if (widget.event.kind == EventKind.STORAGE_SHARED_FILE) {
        list.add(buildStorageSharedFileWidget());
        if (!widget.inQuote) {
          if (eventRelation.zapInfos.isNotEmpty) {
            list.add(buildZapInfoWidgets(themeData));
          }

          list.add(EventReactionsComponent(
            screenshotController: widget.screenshotController,
            event: widget.event,
            eventRelation: eventRelation,
            showDetailBtn: widget.showDetailBtn,
          ));
        }
      } else {
        if (widget.showReplying &&
            StringUtil.isNotBlank(eventRelation.replyOrRootId)) {
          list.add(Selector<SingleEventProvider, Event?>(
              builder: (context, replyEvent, child) {
            if (replyEvent == null) {
              return Container();
            }

            var textStyle = TextStyle(
              color: hintColor,
              fontSize: smallTextSize,
            );
            List<Widget> replyingList = [];
            replyingList.add(Text(
              "${s.Replying}: ",
              style: textStyle,
            ));

            // replyEvent found! show simple reply event info.
            replyingList.add(Container(
              margin: const EdgeInsets.only(
                left: Base.BASE_PADDING_HALF,
              ),
              child: UserPicComponent(
                pubkey: replyEvent.pubkey,
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
                replyEvent.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            )));

            return Container(
              width: double.maxFinite,
              padding: const EdgeInsets.only(
                bottom: Base.BASE_PADDING_HALF,
              ),
              child: Row(
                children: replyingList,
              ),
            );
          }, selector: (context, _provider) {
            if (StringUtil.isBlank(eventRelation.replyOrRootId)) {
              return null;
            }
            return _provider.getEvent(eventRelation.replyOrRootId!);
          }));
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

        if (widget.event.kind == EventKind.POLL) {
          list.add(EventPollComponent(
            event: widget.event,
          ));
        } else if (widget.event.kind == EventKind.ZAP_GOALS ||
            StringUtil.isNotBlank(eventRelation.zapraiser)) {
          list.add(EventZapGoalsComponent(
            event: widget.event,
            eventRelation: eventRelation,
          ));
        }

        if (widget.event.kind == EventKind.FILE_HEADER ||
            widget.event.kind == EventKind.PICTURE ||
            widget.event.kind == EventKind.VIDEO_HORIZONTAL ||
            widget.event.kind == EventKind.VIDEO_VERTICAL) {
          String? m;
          String? url;
          List? imeta;
          String? previewImage;
          List<String> tagList = [];
          for (var tag in widget.event.tags) {
            if (tag.length > 1) {
              var key = tag[0];
              var value = tag[1];
              if (key == "url") {
                url = value;
              } else if (key == "m") {
                m = value;
              } else if (key == "imeta") {
                imeta = tag;
              } else if (key == "t") {
                tagList.add(value);
              }
            }
          }

          if (imeta != null) {
            for (var tagItem in imeta) {
              if (!(tagItem is String)) {
                continue;
              }

              var strs = tagItem.split(" ");
              if (strs.length > 1) {
                var key = strs[0];
                var value = strs[1];
                if (key == "url" && url == null) {
                  url = value;
                } else if (key == "m" && url == null) {
                  m = value;
                } else if (key == "image" && previewImage == null) {
                  previewImage = value;
                }
              }
            }
          }

          if (StringUtil.isNotBlank(url)) {
            if (widget.event.kind == EventKind.VIDEO_HORIZONTAL ||
                widget.event.kind == EventKind.VIDEO_VERTICAL) {
              if (settingProvider.videoPreview == OpenStatus.OPEN &&
                  widget.showVideo) {
                list.add(ContentVideoComponent(url: url!));
              } else {
                list.add(ContentLinkComponent(link: url!));
              }
            } else {
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
                var fileType = PathTypeUtil.getPathType(url!);
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

          if (tagList.isNotEmpty) {
            List<Widget> topicWidgets = [];
            for (var topic in tagList) {
              topicWidgets.add(ContentTagComponent(tag: "#$topic"));
            }

            list.add(Container(
              margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
              child: Wrap(
                spacing: Base.BASE_PADDING_HALF,
                runSpacing: Base.BASE_PADDING_HALF / 2,
                children: topicWidgets,
              ),
            ));
          }
        }

        if (eventRelation.aId != null &&
            eventRelation.aId!.kind == EventKind.LONG_FORM &&
            widget.showLinkedLongForm) {
          list.add(EventQuoteComponent(
            aId: eventRelation.aId!,
          ));
        }

        if (widget.event.kind == EventKind.TORRENTS) {
          var torrentInfo = TorrentInfo.fromEvent(widget.event);
          if (torrentInfo != null) {
            list.add(EventTorrentComponent(torrentInfo));
          }
        }

        if (eventRelation.zapInfos.isNotEmpty) {
          list.add(buildZapInfoWidgets(themeData));
        }

        if (widget.event.kind != EventKind.ZAP &&
            !(widget.event.kind == EventKind.FILE_HEADER && widget.inQuote)) {
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
        eventRelation.aId!.kind == EventKind.COMMUNITY_DEFINITION &&
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
        padding: EdgeInsets.only(
          left: Base.BASE_PADDING + 4,
          right: Base.BASE_PADDING + 4 + (widget.traceMode ? 40 : 0),
          bottom: Base.BASE_PADDING_HALF,
        ),
        child: communityTitle,
      ));
    }

    if (!(widget.inQuote &&
        (widget.event.kind == EventKind.FILE_HEADER ||
            widget.event.kind == EventKind.STORAGE_SHARED_FILE))) {
      eventAllList.add(EventTopComponent(
        event: widget.event,
        pagePubkey: widget.pagePubkey,
      ));
    }

    eventAllList.add(Container(
      width: double.maxFinite,
      padding: EdgeInsets.only(
        left: Base.BASE_PADDING + (widget.traceMode ? 40 : 0),
        right: Base.BASE_PADDING,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
    ));

    return Container(
      // color: Colors.blue,
      // padding: const EdgeInsets.only(top: Base.BASE_PADDING),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: eventAllList,
      ),
    );
  }

  bool forceShowLongContnet = false;

  bool hideLongContent = false;

  Widget buildContentWidget(
      SettingProvider _settingProvider, bool imagePreview, bool videoPreview) {
    var content = widget.event.content;
    if (StringUtil.isBlank(content) &&
        widget.event.kind == EventKind.ZAP &&
        StringUtil.isNotBlank(eventRelation.innerZapContent)) {
      content = eventRelation.innerZapContent!;
    }

    var main = Container(
      width: double.maxFinite,
      child: ContentComponent(
        content: content,
        event: widget.event,
        textOnTap: widget.textOnTap,
        showImage: imagePreview,
        showVideo: videoPreview,
        showLinkPreview: _settingProvider.linkPreview == OpenStatus.OPEN,
        imageListMode: widget.imageListMode,
        eventRelation: eventRelation,
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

    // TODO add hashtag support!!!

    return mdw.MarkdownBlock(
      data: content,
      generator: mdw.MarkdownGenerator(
        generators: [
          mdw.SpanNodeGeneratorWithTag(
            tag: MarkdownMentionUserElementBuilder.TAG,
            generator: (element, config, visitor) {
              return MdwMentionUserNode(element, config, visitor);
            },
          ),
          mdw.SpanNodeGeneratorWithTag(
            tag: MarkdownMentionEventElementBuilder.TAG,
            generator: (element, config, visitor) {
              return MdwMentionEventNode(element, config, visitor);
            },
          ),
          mdw.SpanNodeGeneratorWithTag(
            tag: MarkdownNrelayElementBuilder.TAG,
            generator: (element, config, visitor) {
              return MdwNrelayNode(element, config, visitor);
            },
          ),
        ],
        inlineSyntaxList: [
          MarkdownMentionEventInlineSyntax(),
          MarkdownMentionUserInlineSyntax(),
          MarkdownNaddrInlineSyntax(),
          MarkdownNeventInlineSyntax(),
          MarkdownNprofileInlineSyntax(),
          MarkdownNrelayInlineSyntax(),
        ],
      ),
      config: mdw.MarkdownConfig(configs: [
        mdw.LinkConfig(
            style: TextStyle(
              color: themeData.primaryColor,
              decoration: TextDecoration.underline,
              decorationColor: themeData.primaryColor,
            ),
            onTap: (href) async {
              if (StringUtil.isNotBlank(href)) {
                if (href.indexOf("http") == 0) {
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
                      RouterUtil.router(
                          context, RouterPath.USER, nprofile.pubkey);
                    }
                  } else if (Nip19.isNoteId(link)) {
                    var noteId = Nip19.decode(link);
                    if (StringUtil.isNotBlank(noteId)) {
                      RouterUtil.router(
                          context, RouterPath.EVENT_DETAIL, noteId);
                    }
                  } else if (NIP19Tlv.isNevent(link)) {
                    var nevent = NIP19Tlv.decodeNevent(link);
                    if (nevent != null) {
                      RouterUtil.router(
                          context, RouterPath.EVENT_DETAIL, nevent.id);
                    }
                  } else if (NIP19Tlv.isNaddr(link)) {
                    var naddr = NIP19Tlv.decodeNaddr(link);
                    if (naddr != null) {
                      RouterUtil.router(
                          context, RouterPath.EVENT_DETAIL, naddr.id);
                    }
                  } else if (NIP19Tlv.isNrelay(link)) {
                    var nrelay = NIP19Tlv.decodeNrelay(link);
                    if (nrelay != null) {
                      var result = await ConfirmDialog.show(
                          context, S.of(context).Add_this_relay_to_local);
                      if (result == true) {
                        relayProvider.addRelay(nrelay.addr);
                      }
                    }
                  }
                }
              }
            }),
      ]),
    );
  }

  buildMarkdownWidgetOld(ThemeData themeData) {
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
        MarkdownNaddrInlineSyntax(),
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
          decorationColor: themeData.primaryColor,
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
                var result = await ConfirmDialog.show(
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

  Widget buildStorageSharedFileWidget() {
    var content = widget.event.content;
    var type = eventRelation.type;

    if (!content.startsWith(BASE64.PREFIX)) {
      content = BASE64.PNG_PREFIX + content;
    }

    if (type != null && type.startsWith("image")) {
      return ContentImageComponent(
        imageUrl: content,
        fileMetadata: eventRelation.fileMetadatas[content],
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
        eventRelation: eventRelation,
      );
    }
  }

  Widget buildZapInfoWidgets(ThemeData themeData) {
    List<Widget> list = [];

    list.add(ZapSplitIconComponent(themeData.textTheme.bodyMedium!.fontSize!));

    var imageWidgetHeight = themeData.textTheme.bodyMedium!.fontSize! + 10;
    var imageWidgetWidth = themeData.textTheme.bodyMedium!.fontSize! + 2;
    var imgSize = themeData.textTheme.bodyMedium!.fontSize! + 2;

    List<Widget> userWidgetList = [];
    for (var zapInfo in eventRelation.zapInfos) {
      userWidgetList.add(Container(
        margin: const EdgeInsets.only(left: Base.BASE_PADDING_HALF),
        child: Selector<MetadataProvider, Metadata?>(
          builder: (context, metadata, child) {
            return GestureDetector(
              onTap: () {
                RouterUtil.router(context, RouterPath.USER, zapInfo.pubkey);
              },
              child: Container(
                width: imageWidgetWidth,
                height: imageWidgetHeight,
                alignment: Alignment.center,
                child: UserPicComponent(
                  pubkey: zapInfo.pubkey,
                  width: imgSize,
                  metadata: metadata,
                ),
              ),
            );
          },
          selector: (BuildContext, provider) {
            return provider.getMetadata(zapInfo.pubkey);
          },
        ),
      ));
    }
    list.add(Expanded(
      child: Wrap(
        children: userWidgetList,
      ),
    ));

    return Container(
      margin: EdgeInsets.only(top: Base.BASE_PADDING_HALF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list,
      ),
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
