class AvailabilityModel {
  final String pk;
  final int player;
  final int state;
  final int dayofyear;

  AvailabilityModel(
      {required this.pk,
      required this.state,
      required this.player,
      required this.dayofyear});

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
        pk: json['pk'],
        state: json['state'],
        player: json['player'],
        dayofyear: json['dayofyear']);
  }

  Map<String, dynamic> toJson() =>
      {'pk': pk, 'state': state, 'player': player, 'dayofyear': dayofyear};
}
