class ClassificationModel {
  final int pk;
  final String name;
  final String icon;

  ClassificationModel(
      {required this.pk, required this.name, required this.icon});

  factory ClassificationModel.fromJson(Map<String, dynamic> json) {
    return ClassificationModel(
        pk: json['pk'], name: json['name'], icon: json['icon']);
  }
}
