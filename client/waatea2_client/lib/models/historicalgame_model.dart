class HistoricalGameModel {
  final String playedFor;
  final String playedAgainst;
  final String date;
  final String competition;
  final String position;

  HistoricalGameModel({
    required this.playedFor,
    required this.playedAgainst,
    required this.date,
    required this.competition,
    required this.position,
  });

  factory HistoricalGameModel.fromJson(Map<String, dynamic> json) {
    return HistoricalGameModel(
      playedFor: json['played_for'],
      playedAgainst: json['played_against'],
      date: json['date'],
      competition: json['competition'],
      position: json['position'],
    );
  }
}
