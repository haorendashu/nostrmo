import 'package:flutter/widgets.dart';

class NoticeProvider extends ChangeNotifier {
  List<NoticeData> notices = [];

  DateTime? readTime;

  void onNotice(String replyAddr, String content) {
    notices.add(NoticeData(replyAddr, content, DateTime.now()));
    notifyListeners();
  }

  bool hasNewMessage() {
    if (notices.isNotEmpty &&
        (readTime == null ||
            notices.last.dateTime.millisecondsSinceEpoch >
                readTime!.millisecondsSinceEpoch)) {
      return true;
    }
    return false;
  }

  void setRead() {
    if (notices.isNotEmpty) {
      readTime = notices.last.dateTime;
      notifyListeners();
    }
  }

  void clear() {
    notices.clear();
    notifyListeners();
  }
}

class NoticeData {
  final String url;

  final String content;

  final DateTime dateTime;

  NoticeData(this.url, this.content, this.dateTime);
}
