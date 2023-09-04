class LinkModel {
  final String pk;
  final String name;
  final String url;
  final String icon;

  LinkModel(
      {required this.pk,
      required this.name,
      required this.url,
      required this.icon});

  factory LinkModel.fromJson(Map<String, dynamic> json) {
    return LinkModel(
        pk: json['pk'],
        name: json['name'],
        url: json['url'],
        icon: json['icon']);
  }
}
