import '../consts/feed_data_event_type.dart';

class FeedData {
  String id;

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
    this.id,
    this.name,
    this.feedType, {
    this.sources = const [],
    this.datas = const [],
    this.eventKinds = const [],
    this.eventType = FeedDataEventType.EVENT_ALL,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    map['id'] = id;
    map['name'] = name;
    map['feedType'] = feedType;
    map['sources'] = sources;
    map['datas'] = datas;
    map['eventKinds'] = eventKinds;
    map['eventType'] = eventType;
    return map;
  }

  Map<String, dynamic> toLocalJson() {
    var map = toJson();
    map['datas'] = datas;
    return map;
  }

  static FeedData fromJson(Map<String, dynamic> item) {
    var id = item['id'];
    var name = item['name'];
    var feedType = item['feedType'];
    var sources = item['sources'];
    var datas = item['datas'];
    datas ??= [];
    var eventKinds = item['eventKinds'];
    var eventType = item['eventType'];
    return FeedData(
      id,
      name,
      feedType,
      sources: sources,
      datas: datas,
      eventKinds: eventKinds,
      eventType: eventType,
    );
  }
}
