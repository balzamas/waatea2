class GameModel {
  final String pk;

  final String homeId;
  final String home;

  final String awayId;
  final String away;

  final String date;
  final int dayofyear;
  final String season;
  final bool lineupPublished;

  GameModel({
    required this.pk,
    required this.homeId,
    required this.home,
    required this.awayId,
    required this.away,
    required this.date,
    required this.dayofyear,
    required this.season,
    required this.lineupPublished,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      pk: json['pk'],
      homeId: json['home']['pk'],
      home: json['home']['name'],
      awayId: json['away']['pk'],
      away: json['away']['name'],
      date: json['date'],
      season: json['season'],
      dayofyear: json['dayofyear'],
      lineupPublished: json['lineup_published'],
    );
  }

  Map<String, dynamic> toJson() => {
    'pk': pk,
    'home': homeId,
    'away': awayId,
    'date': date,
    'season': season,
    'dayofyear': dayofyear,
    'lineup_published': lineupPublished,
  };
}
