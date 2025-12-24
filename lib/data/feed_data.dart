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
    List<List<dynamic>> sourcesList = [];
    if (sources is List) {
      for (var source in sources) {
        if (source is List) {
          sourcesList.add(List<dynamic>.from(source));
        }
      }
    }

    var datas = item['datas'];
    List<List<dynamic>> datasList = [];
    if (datas is List) {
      for (var data in datas) {
        if (data is List) {
          datasList.add(List<dynamic>.from(data));
        }
      }
    }

    var eventKinds = item['eventKinds'];
    List<int> eventKindsList = [];
    if (eventKinds is List) {
      for (var kind in eventKinds) {
        if (kind is int) {
          eventKindsList.add(kind);
        } else if (kind is String) {
          eventKindsList.add(int.tryParse(kind) ?? 0);
        } else if (kind is double) {
          eventKindsList.add(kind.toInt());
        }
      }
    }

    var eventType = item['eventType'];
    return FeedData(
      id,
      name,
      feedType,
      sources: sourcesList,
      datas: datasList,
      eventKinds: eventKindsList,
      eventType: eventType,
    );
  }
}
