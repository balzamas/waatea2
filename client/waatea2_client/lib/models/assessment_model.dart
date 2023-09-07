class AssessmentModel {
  final int pk;
  final String name;
  final String icon;

  AssessmentModel({required this.pk, required this.name, required this.icon});

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
        pk: json['pk'], name: json['name'], icon: json['icon']);
  }
}
