import 'dart:convert';
import 'dart:typed_data';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_dart/nostr_dart.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/client/zap/zap.dart';
import 'package:nostrmo/client/zap/zap_action.dart';
import 'package:nostrmo/data/event_reactions.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/event_reactions_provider.dart';
import 'package:nostrmo/router/edit/editor_router.dart';
import 'package:nostrmo/util/lightning_util.dart';
import 'package:nostrmo/util/string_util.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../client/event_relation.dart';
import '../../util/store_util.dart';

class EventReactionsComponent extends StatefulWidget {
  ScreenshotController screenshotController;

  Event event;

  EventRelation eventRelation;

  EventReactionsComponent({
    required this.screenshotController,
    required this.event,
    required this.eventRelation,
  });

  @override
  State<StatefulWidget> createState() {
    return _EventReactionsComponent();
  }
}

class _EventReactionsComponent extends State<EventReactionsComponent> {
  List<Event>? myLikeEvents;

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var fontSize = themeData.textTheme.bodySmall!.fontSize!;

    return Selector<EventReactionsProvider, EventReactions?>(
      builder: (context, eventReactions, child) {
        int replyNum = 0;
        int repostNum = 0;
        int likeNum = 0;
        int zapNum = 0;
        Color likeColor = hintColor;

        if (eventReactions != null) {
          replyNum = eventReactions.replies.length;
          repostNum = eventReactions.repostNum;
          likeNum = eventReactions.likeNum;
          zapNum = eventReactions.zapNum;

          myLikeEvents = eventReactions.myLikeEvents;
        }
        if (myLikeEvents != null && myLikeEvents!.isNotEmpty) {
          likeColor = Colors.red;
        }

        return Container(
          height: 34,
          child: Row(
            children: [
              Expanded(
                  child: EventReactionNumComponent(
                num: replyNum,
                iconData: Icons.comment,
                onTap: onCommmentTap,
                color: hintColor,
                fontSize: fontSize,
              )),
              Expanded(
                  child: EventReactionNumComponent(
                num: repostNum,
                iconData: Icons.repeat,
                onTap: onRepostTap,
                color: hintColor,
                fontSize: fontSize,
              )),
              Expanded(
                  child: EventReactionNumComponent(
                num: likeNum,
                iconData: Icons.favorite,
                onTap: onLikeTap,
                color: likeColor,
                fontSize: fontSize,
              )),
              Expanded(
                child: PopupMenuButton<int>(
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        value: 10,
                        child: Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.orange),
                            Text(" Zap 10")
                          ],
                          mainAxisSize: MainAxisSize.min,
                        ),
                      ),
                      PopupMenuItem(
                        value: 50,
                        child: Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.orange),
                            Text(" Zap 50")
                          ],
                          mainAxisSize: MainAxisSize.min,
                        ),
                      ),
                      PopupMenuItem(
                        value: 100,
                        child: Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.orange),
                            Text(" Zap 100")
                          ],
                          mainAxisSize: MainAxisSize.min,
                        ),
                      ),
                      PopupMenuItem(
                        value: 500,
                        child: Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.orange),
                            Text(" Zap 500")
                          ],
                          mainAxisSize: MainAxisSize.min,
                        ),
                      ),
                      PopupMenuItem(
                        value: 1000,
                        child: Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.orange),
                            Text(" Zap 1000")
                          ],
                          mainAxisSize: MainAxisSize.min,
                        ),
                      ),
                      PopupMenuItem(
                        value: 5000,
                        child: Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.orange),
                            Text(" Zap 5000")
                          ],
                          mainAxisSize: MainAxisSize.min,
                        ),
                      ),
                    ];
                  },
                  onSelected: onZapSelect,
                  child: EventReactionNumComponent(
                    num: zapNum,
                    iconData: Icons.bolt,
                    onTap: null,
                    color: hintColor,
                    fontSize: fontSize,
                  ),
                ),
              ),
              // Expanded(
              //     child: EventReactionNumComponent(
              //   num: zapNum,
              //   iconData: Icons.bolt,
              //   onTap: onZapTap,
              //   color: hintColor,
              //   fontSize: fontSize,
              // )),
              // Expanded(
              //     child: EventReactionNumComponent(
              //   num: 0,
              //   iconData: Icons.share,
              //   onTap: onShareTap,
              //   color: hintColor,
              //   fontSize: fontSize,
              // )),
              Expanded(
                child: PopupMenuButton<String>(
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        value: "copyEvent",
                        child: Text("Copy Note Json"),
                      ),
                      PopupMenuItem(
                        value: "copyPubkey",
                        child: Text("Copy Note Pubkey"),
                      ),
                      PopupMenuItem(
                        value: "copyId",
                        child: Text("Copy Note Id"),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: "share",
                        child: Text("Share"),
                      ),
                      PopupMenuItem(
                        value: "star",
                        child: Text("Star"),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: "broadcase",
                        child: Text("Broadcase"),
                      ),
                      PopupMenuItem(
                        value: "block",
                        child: Text("Block"),
                      ),
                    ];
                  },
                  onSelected: onPopupSelected,
                  child: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: hintColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      selector: (context, _provider) {
        return _provider.get(widget.event.id);
      },
      shouldRebuild: (previous, next) {
        if ((previous == null && next != null) ||
            (previous != null &&
                next != null &&
                (previous.replies.length != next.replies.length ||
                    previous.repostNum != next.repostNum ||
                    previous.likeNum != next.likeNum ||
                    previous.zapNum != next.zapNum))) {
          return true;
        }

        return false;
      },
    );
  }

  void onPopupSelected(String value) {
    if (value == "copyEvent") {
      var text = jsonEncode(widget.event.toJson());
      _doCopy(text);
    } else if (value == "copyPubkey") {
      var text = Nip19.encodePubKey(widget.event.pubKey);
      _doCopy(text);
    } else if (value == "copyId") {
      var text = Nip19.encodeNoteId(widget.event.id);
      _doCopy(text);
    } else if (value == "share") {
      onShareTap();
    } else if (value == "star") {
      // TODO star event
    } else if (value == "broadcase") {
      nostr!.sendEvent(widget.event);
    } else if (value == "block") {
      filterProvider.addBlock(widget.event.pubKey);
    }
  }

  void _doCopy(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      BotToast.showText(text: "Copy success!");
    });
  }

  @override
  void dispose() {
    super.dispose();
    var id = widget.event.id;
    eventReactionsProvider.removePendding(id);
  }

  void onCommmentTap() {
    List<dynamic> tags = [];
    List<dynamic> tagsAddedWhenSend = [];
    tagsAddedWhenSend.add(["e", widget.event.id, "", "reply"]);

    var er = widget.eventRelation;
    tags.add(["p", widget.event.pubKey]);
    if (er.tagPList.isNotEmpty) {
      for (var p in er.tagPList) {
        tags.add(["p", p]);
      }
    }
    if (StringUtil.isNotBlank(er.rootId)) {
      tags.add(["e", er.rootId, "", "root"]);
    }

    // TODO reply maybe change the placeholder in editor router.
    EditorRouter.open(context,
        tags: tags, tagsAddedWhenSend: tagsAddedWhenSend);
  }

  void onRepostTap() {
    nostr!.sendRepost(widget.event.id);
    eventReactionsProvider.addRepost(widget.event.id);
  }

  void onLikeTap() {
    if (myLikeEvents == null || myLikeEvents!.isEmpty) {
      // like
      var likeEvent = nostr!.sendLike(widget.event.id);
      eventReactionsProvider.addLike(widget.event.id, likeEvent);
    } else {
      // delete like
      for (var event in myLikeEvents!) {
        nostr!.deleteLike(event.id);
        eventReactionsProvider.deleteLike(widget.event.id);
      }
    }
  }

  Future<void> onZapSelect(int sats) async {
    await ZapAction.handleZap(context, sats, widget.event.pubKey,
        eventId: widget.event.id);

    // var metadata = metadataProvider.getMetadata(widget.event.pubKey);
    // if (metadata == null) {
    //   BotToast.showText(text: "Metadata can not be found.");
    //   return;
    // }

    // var relays = relayProvider.relayAddrs;

    // if (StringUtil.isNotBlank(metadata.lud16)) {
    //   var lnurl = Zap.getLnurlFromLud16(metadata.lud16!);
    //   if (StringUtil.isNotBlank(lnurl)) {
    //     var lnurl = Zap.getLnurlFromLud16(metadata.lud16!);
    //     if (StringUtil.isBlank(lnurl)) {
    //       BotToast.showText(text: "Gen lnurl error.");
    //       return;
    //     }
    //     var invoiceCode = await Zap.getInvoiceCode(
    //         lnurl: lnurl!,
    //         sats: sats,
    //         recipientPubkey: widget.event.pubKey,
    //         targetNostr: nostr!,
    //         relays: relays);

    //     if (StringUtil.isBlank(invoiceCode)) {
    //       BotToast.showText(text: "Gen invoiceCode error.");
    //       return;
    //     }

    //     await LightningUtil.goToPay(invoiceCode!);
    //   }
    // }
  }

  void onShareTap() {
    widget.screenshotController.capture().then((Uint8List? imageData) async {
      if (imageData != null) {
        if (imageData != null) {
          var tempFile = await StoreUtil.saveBS2TempFile(
            "png",
            imageData,
          );
          Share.shareXFiles([XFile(tempFile)]);
        }
      }
    }).catchError((onError) {
      print(onError);
    });
  }
}

class EventReactionNumComponent extends StatelessWidget {
  IconData iconData;

  int num;

  Function? onTap;

  Color color;

  double fontSize;

  EventReactionNumComponent({
    required this.iconData,
    required this.num,
    required this.onTap,
    required this.color,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    Widget? main;
    var iconWidget = Icon(
      iconData,
      size: 14,
      color: color,
    );
    if (num != 0) {
      String numStr = num.toString();
      if (num > 1000000) {
        numStr = (num / 1000000).toStringAsFixed(1) + "m";
      } else if (num > 1000) {
        numStr = (num / 1000).toStringAsFixed(1) + "k";
      }

      main = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconWidget,
          Container(
            margin: const EdgeInsets.only(left: 4),
            child: Text(
              numStr,
              style: TextStyle(color: color, fontSize: fontSize),
            ),
          ),
        ],
      );
    } else {
      main = iconWidget;
    }

    if (onTap != null) {
      return IconButton(
        onPressed: () {
          onTap!();
        },
        icon: main,
      );
    } else {
      return Container(
        alignment: Alignment.center,
        child: main,
      );
    }
  }
}
