import 'package:flutter/material.dart';
import 'package:nostrmo/component/event/event_id_router_component.dart';

import '../client/event_kind.dart';
import '../client/nip19/nip19.dart';
import '../client/nip19/nip19_tlv.dart';
import '../consts/router_path.dart';
import '../util/router_util.dart';
import '../util/string_util.dart';
import 'content/content_component.dart';
import 'webview_router.dart';

class LinkRouterUtil {
  static void router(BuildContext context, String link) {
    if (link.startsWith("http")) {
      WebViewRouter.open(context, link);
      return;
    }

    var key = link.replaceFirst("nostr:", "");

    if (Nip19.isPubkey(key)) {
      if (key.length > NPUB_LENGTH) {
        key = key.substring(0, NPUB_LENGTH);
      }
      key = Nip19.decode(key);
      RouterUtil.router(context, RouterPath.USER, key);
    } else if (Nip19.isNoteId(key)) {
      if (key.length > NOTEID_LENGTH) {
        key = key.substring(0, NOTEID_LENGTH);
      }
      key = Nip19.decode(key);
      RouterUtil.router(context, RouterPath.THREAD_TRACE, key);
    } else if (NIP19Tlv.isNprofile(key)) {
      var index = Nip19.checkBech32End(key);
      if (index != null) {
        key = key.substring(0, index);
      }

      var nprofile = NIP19Tlv.decodeNprofile(key);
      if (nprofile != null) {
        RouterUtil.router(context, RouterPath.USER, nprofile.pubkey);
      }
    } else if (NIP19Tlv.isNevent(key)) {
      var index = Nip19.checkBech32End(key);
      if (index != null) {
        key = key.substring(0, index);
      }

      var nevent = NIP19Tlv.decodeNevent(key);
      if (nevent != null) {
        var relayAddr = (nevent.relays != null && nevent.relays!.isNotEmpty)
            ? nevent.relays![0]
            : null;
        EventIdRouterComponent.router(context, nevent.id, relayAddr: relayAddr);
      }
    } else if (NIP19Tlv.isNaddr(key)) {
      var index = Nip19.checkBech32End(key);
      if (index != null) {
        key = key.substring(0, index);
      }

      var naddr = NIP19Tlv.decodeNaddr(key);
      if (naddr != null) {
        if (naddr.kind == EventKind.TEXT_NOTE &&
            StringUtil.isNotBlank(naddr.id)) {
          var relayAddr = (naddr.relays != null && naddr.relays!.isNotEmpty)
              ? naddr.relays![0]
              : null;
          EventIdRouterComponent.router(context, naddr.id,
              relayAddr: relayAddr);
        } else if (naddr.kind == EventKind.LONG_FORM &&
            StringUtil.isNotBlank(naddr.id)) {
          // TODO load long form
        } else if (StringUtil.isNotBlank(naddr.author) &&
            naddr.kind == EventKind.METADATA) {
          RouterUtil.router(context, RouterPath.USER, naddr.author);
        }
      }
    }
  }
}
