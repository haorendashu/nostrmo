import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/src/ast.dart';
import 'package:nostrmo/client/nip19/nip19.dart';
import 'package:nostrmo/client/nip19/nip19_tlv.dart';
import 'package:nostrmo/component/content/content_mention_user_component.dart';
import 'package:nostrmo/component/event/event_quote_component.dart';

class MarkdownMentionEventElementBuilder implements MarkdownElementBuilder {
  static const String TAG = "mentionEvent";

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var pureText = element.textContent;
    var nip19Text = pureText.replaceFirst("nostr:", "");

    String? key;
    String? relayAddr;

    if (Nip19.isNoteId(nip19Text)) {
      key = Nip19.decode(nip19Text);
    } else if (NIP19Tlv.isNevent(nip19Text)) {
      var nevent = NIP19Tlv.decodeNevent(nip19Text);
      if (nevent != null) {
        key = nevent.id;
        if (nevent.relays != null && nevent.relays!.isNotEmpty) {
          relayAddr = nevent.relays![0];
        }
      }
    } else if (NIP19Tlv.isNaddr(nip19Text)) {
      var naddr = NIP19Tlv.decodeNaddr(nip19Text);
      if (naddr != null) {
        key = naddr.id;
        if (naddr.relays != null && naddr.relays!.isNotEmpty) {
          relayAddr = naddr.relays![0];
        }
      }
    }

    if (key != null) {
      return EventQuoteComponent(
        id: key,
        eventRelayAddr: relayAddr,
      );
    }
  }

  @override
  void visitElementBefore(md.Element element) {}

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {}

  @override
  Widget? visitElementAfterWithContext(BuildContext context, md.Element element,
      TextStyle? preferredStyle, TextStyle? parentStyle) {
    return null;
  }
}
