class ShowAvailabilityModel {
  final String pk;
  final String home;
  final String away;
  final String date;
  final int dayofyear;
  final String season;
  int isAvailable;
  int isNotAvailable;
  int isMaybe;
  int isNotSet;

  ShowAvailabilityModel({
    required this.pk,
    required this.home,
    required this.away,
    required this.date,
    required this.dayofyear,
    required this.season,
    required this.isAvailable,
    required this.isNotAvailable,
    required this.isMaybe,
    required this.isNotSet,
  });

  factory ShowAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return ShowAvailabilityModel(
      pk: json['pk'],
      home: json['home']['name'],
      away: json['away']['name'],
      date: json['date'],
      dayofyear: json['dayofyear'],
      season: json['season'],
      isAvailable: 0,
      isNotAvailable: 0,
      isMaybe: 0,
      isNotSet: 0,
    );
  }

  Map<String, dynamic> toJson() =>
      {'pk': pk, 'home': home, 'away': away, 'date': date, 'season': season};
}
