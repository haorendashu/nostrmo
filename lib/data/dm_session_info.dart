class DMSessionInfo {
  String? pubkey;

  /// the last readed event created at
  int? readedTime;

  String? value1;

  String? value2;

  String? value3;

  DMSessionInfo(
      {this.pubkey, this.readedTime, this.value1, this.value2, this.value3});

  DMSessionInfo.fromJson(Map<String, dynamic> json) {
    pubkey = json['pubkey'];
    readedTime = json['readed_time'];
    if (readedTime == null || readedTime! < 0) {
      readedTime = 0;
    }
    value1 = json['value1'];
    value2 = json['value2'];
    value3 = json['value3'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pubkey'] = this.pubkey;
    data['readed_time'] = this.readedTime;
    data['value1'] = this.value1;
    data['value2'] = this.value2;
    data['value3'] = this.value3;
    return data;
  }
}
