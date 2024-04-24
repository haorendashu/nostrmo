class Nip96ServerAdaptation {
  String? apiUrl;
  String? downloadUrl;
  String? delegatedToUrl;
  List<int>? supportedNips;
  String? tosUrl;
  List<String>? contentTypes;
  Nip96Plans? plans;

  Nip96ServerAdaptation(
      {this.apiUrl,
      this.downloadUrl,
      this.delegatedToUrl,
      this.supportedNips,
      this.tosUrl,
      this.contentTypes,
      this.plans});

  Nip96ServerAdaptation.fromJson(Map<String, dynamic> json) {
    apiUrl = json['api_url'];
    downloadUrl = json['download_url'];
    delegatedToUrl = json['delegated_to_url'];
    supportedNips = json['supported_nips'].cast<int>();
    tosUrl = json['tos_url'];
    contentTypes = json['content_types'].cast<String>();
    plans =
        json['plans'] != null ? new Nip96Plans.fromJson(json['plans']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['api_url'] = this.apiUrl;
    data['download_url'] = this.downloadUrl;
    data['delegated_to_url'] = this.delegatedToUrl;
    data['supported_nips'] = this.supportedNips;
    data['tos_url'] = this.tosUrl;
    data['content_types'] = this.contentTypes;
    if (this.plans != null) {
      data['plans'] = this.plans!.toJson();
    }
    return data;
  }
}

class Nip96Plans {
  PlanINfo? free;
  // PlanINfo? professional;

  Nip96Plans({this.free});

  Nip96Plans.fromJson(Map<String, dynamic> json) {
    free = json['free'] != null ? PlanINfo.fromJson(json['free']) : null;
    // professional = json['professional'] != null
    //     ? PlanINfo.fromJson(json['professional'])
    //     : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.free != null) {
      data['free'] = this.free!.toJson();
    }
    return data;
  }
}

class PlanINfo {
  String? name;
  bool? isNip98Required;
  String? url;
  int? maxByteSize;
  List<int>? fileExpiration;

  PlanINfo(
      {this.name,
      this.isNip98Required,
      this.url,
      this.maxByteSize,
      this.fileExpiration});

  PlanINfo.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    isNip98Required = json['is_nip98_required'];
    url = json['url'];
    maxByteSize = json['max_byte_size'];
    fileExpiration = json['file_expiration'].cast<int>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['is_nip98_required'] = this.isNip98Required;
    data['url'] = this.url;
    data['max_byte_size'] = this.maxByteSize;
    data['file_expiration'] = this.fileExpiration;
    return data;
  }
}
