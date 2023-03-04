class Metadata {
  String? pubKey;
  String? name;
  String? username;
  String? displayName;
  String? picture;
  String? banner;
  String? website;
  String? about;
  String? nip05;
  String? lud16;
  String? lud06;

  Metadata(
      {this.pubKey,
      this.name,
      this.username,
      this.displayName,
      this.picture,
      this.banner,
      this.website,
      this.about,
      this.nip05,
      this.lud16,
      this.lud06});

  Metadata.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    username = json['username'];
    displayName = json['display_name'];
    picture = json['picture'];
    banner = json['banner'];
    website = json['website'];
    about = json['about'];
    nip05 = json['nip05'];
    lud16 = json['lud16'];
    lud06 = json['lud06'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['username'] = this.username;
    data['display_name'] = this.displayName;
    data['picture'] = this.picture;
    data['banner'] = this.banner;
    data['website'] = this.website;
    data['about'] = this.about;
    data['nip05'] = this.nip05;
    data['lud16'] = this.lud16;
    data['lud06'] = this.lud06;
    return data;
  }
}
