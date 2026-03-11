class WebAppItem {
  String link;

  String name;

  String desc;

  String? image;

  List<String> types;

  WebAppItem(this.link, this.name, this.desc, this.types, {this.image});

  Map<String, dynamic> toJson() {
    return {
      "link": link,
      "name": name,
      "desc": desc,
      "image": image,
      "types": types,
    };
  }
}
