class AvailabilityModel {
  final String pk;
  final int player;
  final int state;

  AvailabilityModel(
      {required this.pk, required this.state, required this.player});

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
        pk: json['pk'], state: json['state'], player: json['player']);
  }

  Map<String, dynamic> toJson() => {'pk': pk, 'state': state, 'player': player};
}
