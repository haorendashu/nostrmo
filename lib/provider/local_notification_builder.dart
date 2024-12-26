import 'package:local_notifier/local_notifier.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/nip04/nip04.dart';
import 'package:nostr_sdk/utils/platform_util.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:window_manager/window_manager.dart';

import '../component/user/simple_name_component.dart';
import '../consts/router_path.dart';
import '../generated/l10n.dart';
import '../router/edit/editor_router.dart';
import '../router/thread/thread_detail_router.dart';

class LocalNotificationBuilder {
  Map<String, int> _sendedCache = {};

  void sendNotification(Event event) async {
    if (PlatformUtil.isPC() &&
        (event.kind == EventKind.TEXT_NOTE ||
            event.kind == EventKind.PRIVATE_DIRECT_MESSAGE ||
            event.kind == EventKind.DIRECT_MESSAGE)) {
      if (_sendedCache[event.id] == null) {
        _sendedCache[event.id] = 1;

        var name = getName(event.pubkey);
        if (event.kind == EventKind.TEXT_NOTE) {
          String titleText = "New note receive";
          String openText = "Open";
          String closeText = "Close";
          String replyText = "Reply";
          if (indexGlobalKey.currentState != null) {
            var s = S.of(indexGlobalKey.currentState!.context);
            titleText = s.New_note_receive;
            openText = s.open;
            closeText = s.close;
            replyText = s.Reply;
          }

          var eventContent = ThreadDetailRouter.getAppBarTitle(event);
          var body = "$name: $eventContent";

          LocalNotification notification = LocalNotification(
            identifier: event.id,
            title: titleText,
            body: body,
            actions: [
              LocalNotificationAction(text: openText),
              LocalNotificationAction(text: closeText),
              LocalNotificationAction(text: replyText),
            ],
          );

          notification.onClick = () {
            notification.close();
            openWindow();
            openNote(event);
          };

          notification.onClickAction = (clickAction) async {
            notification.close();
            if (clickAction == 0) {
              openWindow();
              openNote(event);
            } else if (clickAction == 1) {
            } else if (clickAction == 2) {
              if (indexGlobalKey.currentState != null) {
                openWindow();
                EditorRouter.replyEvent(
                    indexGlobalKey.currentState!.context, event);
              }
            }
          };
          notification.show();
        } else {
          // DM or private DM
          String titleText = "New Message receive";
          String openText = "Open";
          String closeText = "Close";
          if (indexGlobalKey.currentState != null) {
            var s = S.of(indexGlobalKey.currentState!.context);
            titleText = s.New_message_receive;
            openText = s.open;
            closeText = s.close;
          }

          String? eventContent = event.content;
          if (event.kind == EventKind.DIRECT_MESSAGE &&
              NIP04.isEncrypted(eventContent)) {
            eventContent =
                await nostr!.nostrSigner.decrypt(event.pubkey, eventContent);
          }

          if (StringUtil.isNotBlank(eventContent)) {
            eventContent = eventContent!.replaceAll("\r", " ");
            eventContent = eventContent.replaceAll("\n", " ");
            var body = "$name: $eventContent";

            LocalNotification notification = LocalNotification(
              identifier: event.id,
              title: titleText,
              body: body,
              actions: [
                LocalNotificationAction(text: openText),
                LocalNotificationAction(text: closeText),
              ],
            );

            notification.onClick = () {
              notification.close();
              openWindow();
              openDMsPage();
              openDMDetail(event.pubkey);
            };

            notification.onClickAction = (clickAction) async {
              notification.close();
              if (clickAction == 0) {
                openWindow();
                openDMsPage();
                openDMDetail(event.pubkey);
              }
            };
            notification.show();
          }
        }
      }
    }
  }

  void sendDMsNumberNotification(int number) async {
    String titleText = "New Message receive";
    String openText = "Open";
    String closeText = "Close";
    if (indexGlobalKey.currentState != null) {
      var s = S.of(indexGlobalKey.currentState!.context);
      titleText = s.New_message_receive;
      openText = s.open;
      closeText = s.close;
    }

    LocalNotification notification = LocalNotification(
      identifier: StringUtil.rndNameStr(12),
      title: "$number $titleText",
      actions: [
        LocalNotificationAction(text: openText),
        LocalNotificationAction(text: closeText),
      ],
    );

    notification.onClick = () {
      notification.close();
      openWindow();
      openDMsPage();
    };

    notification.onClickAction = (clickAction) async {
      notification.close();
      if (clickAction == 0) {
        openWindow();
        openDMsPage();
      }
    };
    notification.show();
  }

  String getName(String pubkey) {
    var metadata = metadataProvider.getMetadata(pubkey);
    return SimpleNameComponent.getSimpleName(pubkey, metadata);
  }

  openDMsPage() {
    indexProvider.setCurrentTap(3);
  }

  openDMDetail(String pubkey) {
    if (indexGlobalKey.currentState != null) {
      var dmDetail = dmProvider.getSessionDetail(pubkey);
      if (dmDetail != null) {
        RouterUtil.router(indexGlobalKey.currentState!.context,
            RouterPath.DM_DETAIL, dmDetail);
      }
    }
  }

  openNote(Event event) {
    if (indexGlobalKey.currentState != null) {
      RouterUtil.router(indexGlobalKey.currentState!.context,
          RouterPath.getThreadDetailPath(), event);
    }
  }

  openWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }
}
