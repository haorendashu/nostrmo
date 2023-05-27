class CustomEmoji {
  String? name;
  String? filepath;

  CustomEmoji({this.name, this.filepath});

  CustomEmoji.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    filepath = json['filepath'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['filepath'] = this.filepath;
    return data;
  }
}
