class GameModel {
  final String pk;
  final String home;
  final String away;
  final String date;
  final int dayofyear;
  final String season;
  final bool lineup_published;

  GameModel(
      {required this.pk,
      required this.home,
      required this.away,
      required this.date,
      required this.dayofyear,
      required this.season,
      required this.lineup_published});

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
        pk: json['pk'],
        home: json['home']['name'],
        away: json['away']['name'],
        date: json['date'],
        season: json['season'],
        dayofyear: json['dayofyear'],
        lineup_published: json['lineup_published']);
  }

  Map<String, dynamic> toJson() => {
        'pk': pk,
        'home': home,
        'away': away,
        'date': date,
        'season': season,
        'dayofyear': dayofyear,
        'lineup_published': lineup_published
      };
}
