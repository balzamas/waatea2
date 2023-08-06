class ClubModel {
  final String pk;
  final String name;

  ClubModel({required this.pk, required this.name});

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      pk: json['pk'],
      name: json['name'],
    );
  }
}
