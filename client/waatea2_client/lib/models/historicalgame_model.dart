class HistoricalGameModel {
  final String played_for;
  final String played_against;
  final String date;
  final String competition;
  final String position;

  HistoricalGameModel({
    required this.played_for,
    required this.played_against,
    required this.date,
    required this.competition,
    required this.position,
  });

  factory HistoricalGameModel.fromJson(Map<String, dynamic> json) {
    return HistoricalGameModel(
      played_for: json['played_for'],
      played_against: json['played_against'],
      date: json['date'],
      competition: json['competition'],
      position: json['position'],
    );
  }
}
