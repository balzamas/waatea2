class AbonnementModel {
  final int pk;
  final String name;
  final String short;

  AbonnementModel({required this.pk, required this.name, required this.short});

  factory AbonnementModel.fromJson(Map<String, dynamic> json) {
    return AbonnementModel(
        pk: json['pk'], name: json['name'], short: json['short']);
  }
}
