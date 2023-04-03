class LnurlResponse {
  String? callback;
  int? maxSendable;
  int? minSendable;
  String? metadata;
  int? commentAllowed;
  String? tag;
  bool? allowsNostr;
  String? nostrPubkey;

  LnurlResponse(
      {this.callback,
      this.maxSendable,
      this.minSendable,
      this.metadata,
      this.commentAllowed,
      this.tag,
      this.allowsNostr,
      this.nostrPubkey});

  LnurlResponse.fromJson(Map<String, dynamic> json) {
    callback = json['callback'];
    maxSendable = json['maxSendable'];
    minSendable = json['minSendable'];
    metadata = json['metadata'];
    commentAllowed = json['commentAllowed'];
    tag = json['tag'];
    allowsNostr = json['allowsNostr'];
    nostrPubkey = json['nostrPubkey'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['callback'] = this.callback;
    data['maxSendable'] = this.maxSendable;
    data['minSendable'] = this.minSendable;
    data['metadata'] = this.metadata;
    data['commentAllowed'] = this.commentAllowed;
    data['tag'] = this.tag;
    data['allowsNostr'] = this.allowsNostr;
    data['nostrPubkey'] = this.nostrPubkey;
    return data;
  }
}
