import 'package:nostr_sdk/event_kind.dart';

class EventKindType {
  static List<int> SUPPORTED_EVENTS = [
    EventKind.TEXT_NOTE,
    EventKind.REPOST,
    EventKind.GENERIC_REPOST,
    EventKind.PICTURE,
    EventKind.LONG_FORM,
    EventKind.FILE_HEADER,
    EventKind.STORAGE_SHARED_FILE,
    EventKind.TORRENTS,
    EventKind.POLL,
    EventKind.ZAP_GOALS,
    EventKind.VIDEO_HORIZONTAL,
    EventKind.VIDEO_VERTICAL,
    EventKind.COMMENT,
    EventKind.STARTER_PACKS,
    EventKind.MEDIA_STARTER_PACKS,
  ];
}
