class PositionModel {
  final int pk; // You can adjust the data types as needed
  final String position;

  PositionModel({
    required this.pk,
    required this.position,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      pk: json['pk'],
      position: json['position'],
    );
  }
}
