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

  static SyncTaskItem fromJson(Map<String, dynamic> json) {
    List<String>? relays;
    if (json["relays"] != null) {
      relays =
          (json["relays"] as List<dynamic>).map((e) => e.toString()).toList();
    }

    return SyncTaskItem(
      json["syncType"] as int,
      json["value"] as String,
      relays: relays,
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

  Map<String, dynamic> toSimpleJson() {
    var json = {
      "syncType": syncType,
      "value": value,
    };

    if (relays != null && relays!.isNotEmpty) {
      json["relays"] = [...relays!];
    }

    return json;
  }

  SyncTaskItem clone() {
    var jsonMap = toJson();
    return SyncTaskItem.fromJson(jsonMap);
  }

  @override
  String toString() {
    return "SyncTaskItem($syncType, $value, $relays, $startTime, $endTime)";
  }
}
