class Metadata {
  String? pubkey;
  String? name;
  String? displayName;
  String? picture;
  String? banner;
  String? website;
  String? about;
  String? nip05;
  String? lud16;
  String? lud06;
  int? updated_at;
  int? valid;

  Metadata({
    this.pubkey,
    this.name,
    this.displayName,
    this.picture,
    this.banner,
    this.website,
    this.about,
    this.nip05,
    this.lud16,
    this.lud06,
    this.updated_at,
    this.valid,
  });

  Metadata.fromJson(Map<String, dynamic> json) {
    pubkey = json['pub_key'];
    name = json['name'];
    displayName = json['display_name'];
    picture = json['picture'];
    banner = json['banner'];
    website = json['website'];
    about = json['about'];
    if (json['nip05'] != null && json['nip05'] is String) {
      nip05 = json['nip05'];
    }
    lud16 = json['lud16'];
    lud06 = json['lud06'];
    if (json['updated_at'] != null && json['updated_at'] is int) {
      updated_at = json['updated_at'];
    }
    valid = json['valid'];
  }

  Map<String, dynamic> toFullJson() {
    var data = toJson();
    data['pub_key'] = this.pubkey;
    return data;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['display_name'] = this.displayName;
    data['picture'] = this.picture;
    data['banner'] = this.banner;
    data['website'] = this.website;
    data['about'] = this.about;
    data['nip05'] = this.nip05;
    data['lud16'] = this.lud16;
    data['lud06'] = this.lud06;
    data['updated_at'] = this.updated_at;
    data['valid'] = this.valid;
    return data;
  }
}
