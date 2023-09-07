class AbonnementModel {
  final int pk;
  final String name;

  AbonnementModel({required this.pk, required this.name});

  factory AbonnementModel.fromJson(Map<String, dynamic> json) {
    return AbonnementModel(pk: json['pk'], name: json['name']);
  }
}
