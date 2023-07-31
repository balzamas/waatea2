class AvailabilityModel {
  final String pk;
  final int player;
  final int state;
  final int dayofyear;
  final String season;
  final String updated;

  AvailabilityModel(
      {required this.pk,
      required this.state,
      required this.player,
      required this.dayofyear,
      required this.season,
      required this.updated});

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
        pk: json['pk'],
        state: json['state'],
        player: json['player'],
        dayofyear: json['dayofyear'],
        season: json['season'],
        updated: json['updated']);
  }

  Map<String, dynamic> toJson() => {
        'pk': pk,
        'state': state,
        'player': player,
        'dayofyear': dayofyear,
        'season': season,
        'updated': updated
      };
}
