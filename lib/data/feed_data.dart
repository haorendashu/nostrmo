import '../consts/feed_data_event_type.dart';

class FeedData {
  String name;

  int feedType;

  // source List
  // source: [sourceType, sourceValue]
  List<List<dynamic>> sources = [];

  // data List
  // data: [dataType, dataValue]
  List<List<dynamic>> datas = [];

  List<int> eventKinds = [];

  int eventType;

  FeedData(
    this.name,
    this.feedType, {
    this.sources = const [],
    this.datas = const [],
    this.eventKinds = const [],
    this.eventType = FeedDataEventType.EVENT_ALL,
  });
}
