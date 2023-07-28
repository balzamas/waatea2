class AvailabilityModel {
  final String pk;
  final int state;

  AvailabilityModel({required this.pk, required this.state});

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(pk: json['pk'], state: json['state']);
  }

  Map<String, dynamic> toJson() => {'pk': pk, 'state': state};
}
