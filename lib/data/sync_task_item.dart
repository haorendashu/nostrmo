class SyncTaskItem {
  int syncType;
  String value;
  List<String>? relays;
  int? startTime;
  int? endTime;

  SyncTaskItem(
    this.syncType,
    this.value, {
    this.relays,
    this.startTime,
    this.endTime,
  });

  static fromJson(Map<String, dynamic> json) {
    return SyncTaskItem(
      json["syncType"],
      json["value"],
      relays: json["relays"] as List<String>?,
      startTime: json["startTime"] as int?,
      endTime: json["endTime"] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "syncType": syncType,
      "value": value,
      "relays": [...relays ?? []],
      "startTime": startTime,
      "endTime": endTime,
    };
  }

  SyncTaskItem clone() {
    var jsonMap = toJson();
    return SyncTaskItem.fromJson(jsonMap);
  }
}
