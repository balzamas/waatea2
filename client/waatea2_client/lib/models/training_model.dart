class TrainingModel {
  final String pk;
  final int dayofyear;
  final String season;
  final String date;
  final String club;

  TrainingModel(
      {required this.pk,
      required this.dayofyear,
      required this.season,
      required this.date,
      required this.club});

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    return TrainingModel(
        pk: json['pk'],
        dayofyear: json['dayofyear'],
        season: json['season'],
        date: json['date'],
        club: json['club']);
  }

  Map<String, dynamic> toJson() => {
        'pk': pk,
        'dayofyear': dayofyear,
        'season': season,
        'updated': date,
        'club': club
      };
}
