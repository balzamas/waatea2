class AttendanceModel {
  final String pk;
  final int player;
  final bool attended;
  final int dayofyear;
  final String season;

  AttendanceModel(
      {required this.pk,
      required this.attended,
      required this.player,
      required this.dayofyear,
      required this.season});

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
        pk: json['pk'],
        attended: json['attended'],
        player: json['player'],
        dayofyear: json['dayofyear'],
        season: json['season']);
  }

  Map<String, dynamic> toJson() => {
        'pk': pk,
        'attended': attended,
        'player': player,
        'dayofyear': dayofyear,
        'season': season,
      };
}
